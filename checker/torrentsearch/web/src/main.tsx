import React from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query'
import { Download, Search } from 'lucide-react'
import './styles.css'

type Item = {
	category: string
	title: string
	link: string
	pubdate: string | null
	created_at: string | null
	download_dir: string | null
}

type FeedResponse = {
	items: Item[]
	total: number
	categories: string[]
}

const base = `${import.meta.env.BASE_URL}api`
const client = new QueryClient()

function App() {
	const [q, setQ] = React.useState('')
	const [category, setCategory] = React.useState('')
	const [dateFrom, setDateFrom] = React.useState('')
	const [dateTo, setDateTo] = React.useState('')
	const [downloadedOnly, setDownloadedOnly] = React.useState(false)
	const [page, setPage] = React.useState(1)
	const [pageSize, setPageSize] = React.useState(50)
	const [selectedLinks, setSelectedLinks] = React.useState<Set<string>>(new Set())
	const [restoreToken, setRestoreToken] = React.useState<string | null>(null)
	const [deletedCount, setDeletedCount] = React.useState(0)
	const params = new URLSearchParams({ q, page: String(page), page_size: String(pageSize) })

	if (category) params.set('category', category)
	if (dateFrom) params.set('date_from', dateFrom)
	if (dateTo) params.set('date_to', dateTo)
	if (downloadedOnly) params.set('downloaded', '1')

	const data = useQuery({
		queryKey: ['feed', params.toString()],
		queryFn: async () => {
			const response = await fetch(`${base}/feed-data?${params}`)
			if (!response.ok) throw Error('取得に失敗しました')
			return response.json() as Promise<FeedResponse>
		},
	})
	const pages = Math.max(1, Math.ceil((data.data?.total ?? 0) / pageSize))
	const total = data.data?.total ?? 0
	const categories = data.data?.categories ?? []
	const pageItems = data.data?.items ?? []
	const rangeStart = total === 0 ? 0 : (page - 1) * pageSize + 1
	const rangeEnd = Math.min(page * pageSize, total)
	const allPageItemsSelected = pageItems.length > 0 && pageItems.every(item => selectedLinks.has(item.link))
	const updateDateFrom = (value: string) => {
		setDateFrom(value)
		setDateTo(value)
		setPage(1)
	}
	const clearDateRange = () => {
		setDateFrom('')
		setDateTo('')
		setPage(1)
		setSelectedLinks(new Set())
	}
	const clearKeyword = () => {
		setQ('')
		setPage(1)
		setSelectedLinks(new Set())
	}
	const updatePageSize = (value: number) => {
		setPageSize(value)
		setPage(1)
		setSelectedLinks(new Set())
	}
	const selectCategory = (value: string) => {
		setCategory(value)
		setPage(1)
	}
	const toggleDownloadedOnly = () => {
		setDownloadedOnly(current => !current)
		setPage(1)
		setSelectedLinks(new Set())
	}
	const toggleSelected = (link: string) => {
		setSelectedLinks(current => {
			const next = new Set(current)
			if (next.has(link)) next.delete(link)
			else next.add(link)
			return next
		})
	}
	const togglePageSelection = (checked: boolean) => {
		setSelectedLinks(current => {
			const next = new Set(current)
			pageItems.forEach(item => {
				if (checked) next.add(item.link)
				else next.delete(item.link)
			})
			return next
		})
	}
	const handleDownload = () => {
		if (!selectedLinks.size || !window.confirm(`選択した${selectedLinks.size}件をダウンロードしますか？`)) return
		data.data?.items.filter(item => selectedLinks.has(item.link)).forEach(item => window.open(item.link, '_blank', 'noopener,noreferrer'))
		setSelectedLinks(new Set())
	}
	const handleDelete = async () => {
		if (!selectedLinks.size || !window.confirm(`選択した${selectedLinks.size}件を削除しますか？`)) return
		try {
			const response = await fetch(`${base}/feed-data`, { method: 'DELETE', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ links: Array.from(selectedLinks) }) })
			if (!response.ok) throw Error('削除に失敗しました')
			const result = await response.json() as { deleted: number; restore_token: string }
			setSelectedLinks(new Set())
			setDeletedCount(result.deleted)
			setRestoreToken(result.restore_token)
			await data.refetch()
		} catch (error) {
			window.alert(error instanceof Error ? error.message : '削除に失敗しました')
		}
	}
	const handleRestore = async () => {
		if (!restoreToken) return
		try {
			const response = await fetch(`${base}/feed-data/restore`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: restoreToken }) })
			if (!response.ok) throw Error('復元に失敗しました')
			setRestoreToken(null)
			setDeletedCount(0)
			await data.refetch()
		} catch (error) {
			window.alert(error instanceof Error ? error.message : '復元に失敗しました')
		}
	}
	const pagination = <div className="pagination"><button disabled={page === 1} onClick={() => setPage(1)}>最初へ</button><button disabled={page === 1} onClick={() => setPage(page - 1)}>前へ</button><b>{rangeStart}-{rangeEnd} / {total}</b><button disabled={page === pages} onClick={() => setPage(page + 1)}>次へ</button><button disabled={page === pages} onClick={() => setPage(pages)}>最後へ</button><select value={pageSize} onChange={event => updatePageSize(Number(event.target.value))} aria-label="表示件数"><option value="10">10件</option><option value="20">20件</option><option value="50">50件</option><option value="100">100件</option></select></div>

	return <main>
		<header>
			<div>
				<div className="title-row">
					<h2>た、種ぇぇ</h2>
					<nav className="category-filters" aria-label="カテゴリ絞り込み">
						<button className={category === '' ? 'category-button active' : 'category-button'} onClick={() => selectCategory('')}>all</button>
						{categories.map(item => <button key={item} className={category === item ? 'category-button active' : 'category-button'} onClick={() => selectCategory(item)}>{item}</button>)}
					</nav>
				</div>
			</div>
		</header>
		<div className="search">
			<Search size={18}/>
			<input value={q} onChange={event => { setQ(event.target.value); setPage(1) }} placeholder="タイトルまたはリンクを検索"/><button className="clear-keyword" onClick={clearKeyword} aria-label="検索キーワードを全消去">×</button>
			<span className="date-range-label">取得日時で絞り込み</span>
			<label className="date-field"><span>開始日</span><input type="date" value={dateFrom} onChange={event => updateDateFrom(event.target.value)} aria-label="取得日時の開始日"/></label>
			<span>～</span>
			<label className="date-field"><span>終了日</span><input type="date" value={dateTo} onChange={event => { setDateTo(event.target.value); setPage(1) }} aria-label="取得日時の終了日"/></label><button className="clear-date" onClick={clearDateRange}>クリア</button>
		</div>
		{pagination}
		{restoreToken && <div className="undo-banner">{deletedCount}件削除しました<button onClick={handleRestore}>元に戻す</button></div>}
		<section>
			<div className="table-toolbar"><button className="action-download" disabled={!selectedLinks.size} onClick={handleDownload}>ダウンロード</button><button className="action-delete" disabled={!selectedLinks.size} onClick={handleDelete}>削除</button><button className={downloadedOnly ? 'action-downloaded active' : 'action-downloaded'} onClick={toggleDownloadedOnly}>DL済み</button></div>
			{data.isLoading ? '読み込み中...' : data.isError ? '取得に失敗しました' : <table>
				<thead><tr><th className="select-column"><input type="checkbox" checked={allPageItemsSelected} onChange={event => togglePageSelection(event.target.checked)} aria-label="このページの全行を選択"/></th><th>カテゴリ</th><th>タイトル</th><th>URL</th><th>取得日時</th><th>DL</th></tr></thead>
				<tbody>{data.data?.items.map(item => <tr key={item.link} className={selectedLinks.has(item.link) ? 'selected' : ''} onClick={() => toggleSelected(item.link)}>
					<td className="select-column"><input type="checkbox" checked={selectedLinks.has(item.link)} onChange={() => toggleSelected(item.link)} onClick={event => event.stopPropagation()} aria-label={`${item.title}を選択`}/></td>
					<td><span>{item.category}</span></td>
					<td><b>{item.title}</b></td>
					<td><a className="download-link" href={item.link} target="_blank" rel="noreferrer" aria-label={`${item.title}をダウンロード`} title="ダウンロード"><Download size={16}/></a></td>
					<td>{item.created_at ?? '-'}</td>
					<td className="download-status" title={item.download_dir ?? undefined}>{item.download_dir ? '○' : ''}</td>
				</tr>)}</tbody>
			</table>}
		</section>
		<footer>{pagination}</footer>
	</main>
}

createRoot(document.getElementById('root')!).render(<QueryClientProvider client={client}><App/></QueryClientProvider>)
