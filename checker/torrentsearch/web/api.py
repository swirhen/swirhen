from pathlib import Path
import sqlite3
from fastapi import FastAPI, Query
app=FastAPI(title='Torrent Feed Admin API')
DB=Path(__file__).resolve().parents[1]/'nyaatorrent_feed.db'
@app.get('/api/health')
def health(): return {'status':'ok'}
@app.get('/api/feed-data')
def feed(q:str='',page:int=Query(1,ge=1),page_size:int=Query(50,ge=1,le=200)):
    where=' WHERE title LIKE ? OR link LIKE ?' if q else ''; args=[f'%{q}%',f'%{q}%'] if q else []; off=(page-1)*page_size
    with sqlite3.connect(DB) as c:
        total=c.execute('SELECT COUNT(*) FROM feed_data'+where,args).fetchone()[0]
        rows=c.execute('SELECT category,title,link,pubdate,created_at,download_dir FROM feed_data'+where+' ORDER BY created_at DESC LIMIT ? OFFSET ?',args+[page_size,off]).fetchall()
    return {'items':[dict(zip(('category','title','link','pubdate','created_at','download_dir'),r)) for r in rows],'total':total}
