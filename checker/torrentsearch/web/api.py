from pathlib import Path
import hashlib
import hmac
import os
import sqlite3
import time
from uuid import uuid4
from fastapi import Cookie, Depends, FastAPI, HTTPException, Query, Response
from pydantic import BaseModel
app=FastAPI(title='Torrent Feed Admin API')
DB=Path(__file__).resolve().parents[1]/'nyaatorrent_feed.db'
deleted_batches: dict[str, list[dict]] = {}
AUTH_COOKIE='torrent_admin_session'
SESSION_TTL=60 * 60 * 12
USERNAME=os.getenv('TORRENT_ADMIN_USERNAME', 'dankogai')
PASSWORD=os.getenv('TORRENT_ADMIN_PASSWORD', '')
SECRET=os.getenv('TORRENT_ADMIN_SECRET', '')

class FeedDeleteRequest(BaseModel):
    links: list[str]

class FeedRestoreRequest(BaseModel):
    token: str

class LoginRequest(BaseModel):
    username: str
    password: str

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
@app.get('/api/feed-data')
def feed(_auth=Depends(require_auth), q:str='', category:str='', date_from:str='', date_to:str='', downloaded:int=Query(0,ge=0,le=1), page:int=Query(1,ge=1), page_size:int=Query(50,ge=1,le=100)):
    conditions=[]; args=[]
    if q:
        conditions.append('(title LIKE ? OR link LIKE ?)')
        args.extend([f'%{q}%',f'%{q}%'])
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
    with sqlite3.connect(DB) as c:
        categories=[row[0] for row in c.execute('SELECT DISTINCT category FROM feed_data WHERE category IS NOT NULL ORDER BY category')]
        total=c.execute('SELECT COUNT(*) FROM feed_data'+where,args).fetchone()[0]
        rows=c.execute('SELECT category,title,link,pubdate,created_at,download_dir FROM feed_data'+where+' ORDER BY created_at DESC LIMIT ? OFFSET ?',args+[page_size,off]).fetchall()
    return {'items':[dict(zip(('category','title','link','pubdate','created_at','download_dir'),r)) for r in rows],'total':total,'categories':categories}

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
