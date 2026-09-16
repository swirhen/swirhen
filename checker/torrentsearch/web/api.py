from pathlib import Path
import hashlib
import hmac
import json
import os
import sqlite3
import time
from uuid import uuid4
from typing import Dict
import sys
from fastapi import Cookie, Depends, FastAPI, HTTPException, Query, Response
from pydantic import BaseModel
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import torrent_search_common as tsc
app=FastAPI(title='Torrent Feed Admin API')
DB=Path(__file__).resolve().parents[1]/'nyaatorrent_feed.db'
ARCHIVE_DB=Path(__file__).resolve().parents[1]/'nyaatorrent_feed_before_2023.db'
IDPASS_FILE=Path(__file__).resolve().parents[1]/'idpass.txt'
DOWNLOAD_SETTINGS_FILE=Path(__file__).resolve().parents[1]/'download_settings.json'
deleted_batches: dict[str, list[dict]] = {}
AUTH_COOKIE='torrent_admin_session'
SESSION_TTL=60 * 60 * 24 * 180
def load_local_credentials():
    try:
        lines=IDPASS_FILE.read_text(encoding='utf-8').splitlines()
    except OSError:
        return 'dankogai', ''
    return (lines[0].strip() if lines else 'dankogai', lines[1].strip() if len(lines) > 1 else '')

LOCAL_USERNAME, LOCAL_PASSWORD=load_local_credentials()
USERNAME=os.getenv('TORRENT_ADMIN_USERNAME', LOCAL_USERNAME)
PASSWORD=os.getenv('TORRENT_ADMIN_PASSWORD', LOCAL_PASSWORD)
SECRET=os.getenv('TORRENT_ADMIN_SECRET', 'local-debug-secret' if IDPASS_FILE.is_file() else '')

class FeedDeleteRequest(BaseModel):
    links: list[str]

class FeedRestoreRequest(BaseModel):
    token: str

class LoginRequest(BaseModel):
    username: str
    password: str

class DownloadSettings(BaseModel):
    root_dir: str = ''
    category_dirs: Dict[str, str] = {}

class FeedDownloadRequest(BaseModel):
    links: list[str]
    source: str = 'current'

def require_auth(session: str | None = Cookie(default=None, alias=AUTH_COOKIE)):
    if not PASSWORD or not SECRET or not session:
        raise HTTPException(status_code=401, detail='認証が必要です')
    try:
        issued, token = session.split(':', 1)
        issued_at = int(issued)
    except ValueError:
        raise HTTPException(status_code=401, detail='認証が必要です')
    expected = hmac.new(SECRET.encode(), f'{issued_at}:{USERNAME}'.encode(), hashlib.sha256).hexdigest()
    if time.time() - issued_at > SESSION_TTL or not hmac.compare_digest(token, expected):
        raise HTTPException(status_code=401, detail='認証が必要です')

@app.get('/api/health')
def health(): return {'status':'ok'}

@app.get('/api/session')
def session(_auth=Depends(require_auth)):
    return {'authenticated': True}

@app.post('/api/login')
def login(payload: LoginRequest, response: Response):
    if not PASSWORD or not SECRET or not hmac.compare_digest(payload.username, USERNAME) or not hmac.compare_digest(payload.password, PASSWORD):
        raise HTTPException(status_code=401, detail='ユーザー名またはパスワードが違います')
    issued_at=int(time.time())
    token=hmac.new(SECRET.encode(), f'{issued_at}:{USERNAME}'.encode(), hashlib.sha256).hexdigest()
    response.set_cookie(AUTH_COOKIE, f'{issued_at}:{token}', httponly=True, samesite='lax', max_age=SESSION_TTL)
    return {'authenticated': True}

@app.post('/api/logout')
def logout(response: Response):
    response.delete_cookie(AUTH_COOKIE)
    return {'authenticated': False}

@app.get('/api/download-settings')
def get_download_settings(_auth=Depends(require_auth)):
    try:
        settings=json.loads(DOWNLOAD_SETTINGS_FILE.read_text(encoding='utf-8'))
    except (OSError, json.JSONDecodeError):
        settings={}
    return DownloadSettings(**settings).model_dump()

@app.put('/api/download-settings')
def update_download_settings(payload: DownloadSettings, _auth=Depends(require_auth)):
    settings={
        'root_dir': payload.root_dir.strip(),
        'category_dirs': {category: path.strip() for category, path in payload.category_dirs.items()},
    }
    temporary=DOWNLOAD_SETTINGS_FILE.with_suffix('.json.tmp')
    temporary.write_text(json.dumps(settings, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temporary.replace(DOWNLOAD_SETTINGS_FILE)
    return settings

@app.post('/api/feed-data/download')
def download_feed(payload: FeedDownloadRequest, _auth=Depends(require_auth)):
    if payload.source not in ('current', 'archive'):
        raise HTTPException(status_code=422, detail='invalid source')
    if not payload.links:
        return {'downloaded': [], 'failed': []}
    try:
        settings=json.loads(DOWNLOAD_SETTINGS_FILE.read_text(encoding='utf-8'))
    except (OSError, json.JSONDecodeError):
        settings={}
    download_settings=DownloadSettings(**settings)
    if not download_settings.root_dir.strip():
        raise HTTPException(status_code=422, detail='ルートディレクトリが設定されていません')
    category_dirs=download_settings.category_dirs
    placeholders=','.join('?' for _ in payload.links)
    with sqlite3.connect(get_db(payload.source)) as c:
        rows=c.execute(
            f'SELECT category, title, link FROM feed_data WHERE link IN ({placeholders})',
            payload.links,
        ).fetchall()
    items={row[2]: row for row in rows}
    downloaded=[]
    failed=[]
    for link in payload.links:
        item=items.get(link)
        if item is None:
            failed.append({'link': link, 'reason': 'データが見つかりません'})
            continue
        category, title, item_link=item
        category_dir=category_dirs.get(category, '').strip()
        destination=Path(download_settings.root_dir.strip())
        if category_dir:
            destination /= category_dir
        filename=f'{tsc.sanitize_filename(title)}.torrent'
        try:
            destination.mkdir(parents=True, exist_ok=True)
            torrent_data=tsc.download_torrent(item_link)
            if torrent_data is None:
                raise OSError('ダウンロードに失敗しました')
            (destination / filename).write_bytes(torrent_data)
            with sqlite3.connect(get_db(payload.source)) as c:
                c.execute('UPDATE feed_data SET download_dir = ?, download_failed_at = NULL WHERE link = ?', (str(destination), item_link))
                c.commit()
            downloaded.append({'category': category, 'title': title, 'filename': filename, 'path': str(destination / filename)})
        except OSError as error:
            failed.append({'category': category, 'title': title, 'link': item_link, 'reason': str(error)})
    return {'downloaded': downloaded, 'failed': failed}

def get_db(source: str):
    if source == 'archive':
        return ARCHIVE_DB
    return DB
@app.get('/api/feed-data')
def feed(_auth=Depends(require_auth), q:str='', category:str='', date_from:str='', date_to:str='', downloaded:int=Query(0,ge=0,le=1), page:int=Query(1,ge=1), page_size:int=Query(50,ge=1,le=100), source:str=Query('current', pattern='^(current|archive)$')):
    conditions=[]; args=[]
    if q:
        conditions.append('title LIKE ?')
        args.append(f'%{q}%')
    if category:
        conditions.append('category = ?')
        args.append(category)
    if date_from:
        conditions.append('date(created_at) >= date(?)')
        args.append(date_from)
    if date_to:
        conditions.append('date(created_at) <= date(?)')
        args.append(date_to)
    if downloaded:
        conditions.append('download_dir IS NOT NULL')
    where=f" WHERE {' AND '.join(conditions)}" if conditions else ''
    off=(page-1)*page_size
    with sqlite3.connect(get_db(source)) as c:
        categories=[row[0] for row in c.execute('SELECT DISTINCT category FROM feed_data WHERE category IS NOT NULL ORDER BY category')]
        total=c.execute('SELECT COUNT(*) FROM feed_data'+where,args).fetchone()[0]
        rows=c.execute('SELECT category,title,link,pubdate,created_at,download_dir FROM feed_data'+where+' ORDER BY created_at DESC LIMIT ? OFFSET ?',args+[page_size,off]).fetchall()
    return {'items':[dict(zip(('category','title','link','pubdate','created_at','download_dir'),r)) for r in rows],'total':total,'categories':categories,'source':source}

@app.delete('/api/feed-data')
def delete_feed(payload: FeedDeleteRequest, _auth=Depends(require_auth)):
    if not payload.links:
        return {'deleted': 0}
    placeholders=','.join('?' for _ in payload.links)
    with sqlite3.connect(DB) as c:
        c.row_factory=sqlite3.Row
        deleted_rows=c.execute(f'SELECT category,title,link,pubdate,created_at,download_dir FROM feed_data WHERE link IN ({placeholders})', payload.links).fetchall()
        cursor=c.execute(f'DELETE FROM feed_data WHERE link IN ({placeholders})', payload.links)
        deleted=cursor.rowcount
        c.commit()
    token=str(uuid4())
    deleted_batches[token]=[dict(row) for row in deleted_rows]
    return {'deleted': deleted, 'restore_token': token}

@app.post('/api/feed-data/restore')
def restore_feed(payload: FeedRestoreRequest, _auth=Depends(require_auth)):
    rows=deleted_batches.pop(payload.token, None)
    if rows is None:
        return {'restored': 0}
    with sqlite3.connect(DB) as c:
        c.executemany(
            'INSERT OR IGNORE INTO feed_data (category,title,link,pubdate,created_at,download_dir) VALUES (?,?,?,?,?,?)',
            [[row[key] for key in ('category','title','link','pubdate','created_at','download_dir')] for row in rows],
        )
        c.commit()
    return {'restored': len(rows)}
