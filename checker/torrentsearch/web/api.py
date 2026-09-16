from pathlib import Path
import sqlite3
from uuid import uuid4
from fastapi import FastAPI, Query
from pydantic import BaseModel
app=FastAPI(title='Torrent Feed Admin API')
DB=Path(__file__).resolve().parents[1]/'nyaatorrent_feed.db'
deleted_batches: dict[str, list[dict]] = {}

class FeedDeleteRequest(BaseModel):
    links: list[str]

class FeedRestoreRequest(BaseModel):
    token: str
@app.get('/api/health')
def health(): return {'status':'ok'}
@app.get('/api/feed-data')
def feed(q:str='', category:str='', date_from:str='', date_to:str='', page:int=Query(1,ge=1), page_size:int=Query(50,ge=1,le=200)):
    conditions=[]; args=[]
    if q:
        conditions.append('(title LIKE ? OR link LIKE ?)')
        args.extend([f'%{q}%',f'%{q}%'])
    if category:
        conditions.append('category = ?')
        args.append(category)
    if date_from:
        conditions.append('date(pubdate) >= date(?)')
        args.append(date_from)
    if date_to:
        conditions.append('date(pubdate) <= date(?)')
        args.append(date_to)
    where=f" WHERE {' AND '.join(conditions)}" if conditions else ''
    off=(page-1)*page_size
    with sqlite3.connect(DB) as c:
        categories=[row[0] for row in c.execute('SELECT DISTINCT category FROM feed_data WHERE category IS NOT NULL ORDER BY category')]
        total=c.execute('SELECT COUNT(*) FROM feed_data'+where,args).fetchone()[0]
        rows=c.execute('SELECT category,title,link,pubdate,created_at,download_dir FROM feed_data'+where+' ORDER BY created_at DESC LIMIT ? OFFSET ?',args+[page_size,off]).fetchall()
    return {'items':[dict(zip(('category','title','link','pubdate','created_at','download_dir'),r)) for r in rows],'total':total,'categories':categories}

@app.delete('/api/feed-data')
def delete_feed(payload: FeedDeleteRequest):
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
def restore_feed(payload: FeedRestoreRequest):
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
