import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { ChevronLeft, ChevronRight, Download, Pencil, Search, Trash2, X } from 'lucide-react'

const PAGE_SIZE = 50
const API_BASE = `${import.meta.env.BASE_URL}api`

type FeedItem = {
  category: string
  title: string
  link: string
  pubdate: string | null
  created_at: string | null
  download_dir: string | null
  download_failed_at: string | null
}

type FeedResponse = { items: FeedItem[]; total: number; page: number; page_size: number }

async function fetchFeed(params: URLSearchParams): Promise<FeedResponse> {
  const response = await fetch(`${API_BASE}/feed-data?${params}`)
  if (!response.ok) throw new Error('一覧の取得に失敗しました')
  return response.json()
}

function App() {
  const queryClient = useQueryClient()
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('all')
  const [state, setState] = useState('all')
  const [page, setPage] = useState(1)
  const [editing, setEditing] = useState<FeedItem | null>(null)
  const params = new URLSearchParams({ q: query, category, state, page: String(page), page_size: String(PAGE_SIZE) })
  const feed = useQuery({ queryKey: ['feed', params.toString()], queryFn: () => fetchFeed(params) })
  const totalPages = feed.data ? Math.max(1, Math.ceil(feed.data.total / PAGE_SIZE)) : 1

  function updateFilter(setter: (value: string) => void, value: string) {
    setter(value)
    setPage(1)
  }

  async function remove(item: FeedItem) {
    if (!window.confirm(`削除しますか？\n${item.title}`)) return
    await fetch(`${API_BASE}/feed-data?link=${encodeURIComponent(item.link)}`, { method: 'DELETE' })
    await queryClient.invalidateQueries({ queryKey: ['feed'] })
  }

  return (
    <main className="shell">
      <header className="masthead">
        <div>
          <p className="eyebrow">TORRENTSEARCH / FEED DATA</p>
          <h1>Feed control room</h1>
          <p className="subhead">RSSで収集した種データを検索・編集します。</p>
        </div>
        <div className="total-badge"><strong>{feed.data?.total.toLocaleString() ?? '...'}</strong><span>records</span></div>
      </header>

      <section className="toolbar" aria-label="検索条件">
        <label className="searchbox"><Search size={18} /><input value={query} onChange={(event) => updateFilter(setQuery, event.target.value)} placeholder="タイトルまたはリンクを検索" /></label>
        <select value={category} onChange={(event) => updateFilter(setCategory, event.target.value)}><option value="all">全カテゴリ</option><option value="anime">anime</option><option value="av">av</option></select>
        <select value={state} onChange={(event) => updateFilter(setState, event.target.value)}><option value="all">全状態</option><option value="pending">未ダウンロード</option><option value="downloaded">ダウンロード済み</option></select>
      </section>

      <section className="table-wrap">
        {feed.isLoading && <div className="state">読み込み中...</div>}
        {feed.isError && <div className="state error">{(feed.error as Error).message}</div>}
        {feed.data && <table><thead><tr><th>カテゴリ</th><th>タイトル</th><th>公開日時</th><th>取得日時</th><th>状態</th><th aria-label="操作" /></tr></thead><tbody>
          {feed.data.items.map((item) => <tr key={item.link}><td><span className="category">{item.category}</span></td><td><div className="title">{item.title}</div><a href={item.link} target="_blank" rel="noreferrer">{item.link}</a></td><td>{item.pubdate ?? '-'}</td><td>{item.created_at ?? '-'}</td><td>{item.download_dir ? <span className="status done"><Download size={14} />済み</span> : <span className="status pending">未取得</span>}</td><td className="actions"><button title="編集" onClick={() => setEditing(item)}><Pencil size={16} /></button><button className="danger" title="削除" onClick={() => remove(item)}><Trash2 size={16} /></button></td></tr>)}
        </tbody></table>}
        {feed.data && feed.data.items.length === 0 && <div className="state">該当するデータがありません。</div>}
      </section>

      <footer className="pagination"><span>{feed.data ? `${(page - 1) * PAGE_SIZE + 1}-${Math.min(page * PAGE_SIZE, feed.data.total)} / ${feed.data.total}` : ''}</span><div><button disabled={page <= 1} onClick={() => setPage(page - 1)}><ChevronLeft size={18} /></button><b>{page} / {totalPages}</b><button disabled={page >= totalPages} onClick={() => setPage(page + 1)}><ChevronRight size={18} /></button></div></footer>
      {editing && <EditDialog item={editing} close={() => setEditing(null)} saved={() => { setEditing(null); queryClient.invalidateQueries({ queryKey: ['feed'] }) }} />}
    </main>
  )
}

function EditDialog({ item, close, saved }: { item: FeedItem; close: () => void; saved: () => void }) {
  const [title, setTitle] = useState(item.title)
  const [category, setCategory] = useState(item.category)
  const [downloadDir, setDownloadDir] = useState(item.download_dir ?? '')
  const [saving, setSaving] = useState(false)
  async function submit(event: React.FormEvent) {
    event.preventDefault(); setSaving(true)
    await fetch(`${API_BASE}/feed-data`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ link: item.link, title, category, download_dir: downloadDir || null }) })
    saved()
  }
  return <div className="modal-backdrop"><form className="modal" onSubmit={submit}><header><div><p className="eyebrow">EDIT RECORD</p><h2>フィード情報を編集</h2></div><button type="button" onClick={close}><X size={18} /></button></header><label>タイトル<input value={title} onChange={(event) => setTitle(event.target.value)} required /></label><label>カテゴリ<input value={category} onChange={(event) => setCategory(event.target.value)} required /></label><label>ダウンロード先<input value={downloadDir} onChange={(event) => setDownloadDir(event.target.value)} placeholder="未ダウンロードなら空欄" /></label><p className="link-preview">{item.link}</p><button className="save" disabled={saving}>{saving ? '保存中...' : '保存する'}</button></form></div>
}

export default App
