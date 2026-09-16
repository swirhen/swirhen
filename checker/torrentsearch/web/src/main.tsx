import React from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query'
import { Download, HardDriveDownload, LogOut, RefreshCw, Search } from 'lucide-react'
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
	source: 'current' | 'archive'
}

type SearchCondition = {
	category: string
	keyword: string
}

type DownloadResult = {
	downloaded: { category: string; title: string; filename: string; path: string }[]
	failed: { category?: string; title?: string; link: string; reason: string }[]
}

type PasswordCredentialConstructor = new (data: { id: string; password: string }) => Credential

const base = `${import.meta.env.BASE_URL}api`
const client = new QueryClient()
const initialSearchParams = new URLSearchParams(window.location.search)
const initialCategory = initialSearchParams.get('c') ?? ''
const initialKeyword = initialSearchParams.get('q') ?? ''
const categoryOrder = ['av', 'doujin', 'manga', 'pictures', 'game', 'anime', 'comic', 'music', 'live']
const pinkCategories = new Set(['av', 'doujin', 'manga', 'pictures', 'game'])
const downloadCategories = ['av', 'doujin', 'manga', 'pictures', 'game', 'anime', 'comic', 'music', 'live']

function formatCreatedAt(value: string | null) {
	return value ? value.replace('T', ' ').slice(0, 16) : '-'
}

function App() {
	const [q, setQ] = React.useState(initialKeyword)
	const [authenticated, setAuthenticated] = React.useState(false)
	const [authChecking, setAuthChecking] = React.useState(true)
	const [username, setUsername] = React.useState('')
	const [password, setPassword] = React.useState('')
	const [loginError, setLoginError] = React.useState('')
	const [category, setCategory] = React.useState(initialCategory)
	const [source, setSource] = React.useState<'current' | 'archive'>('current')
	const [dateFrom, setDateFrom] = React.useState('')
	const [dateTo, setDateTo] = React.useState('')
	const dateFromPickerRef = React.useRef<HTMLInputElement>(null)
	const dateToPickerRef = React.useRef<HTMLInputElement>(null)
	const [downloadedOnly, setDownloadedOnly] = React.useState(false)
	const [notDownloadedOnly, setNotDownloadedOnly] = React.useState(false)
	const [page, setPage] = React.useState(1)
	const [pageSize, setPageSize] = React.useState(50)
	const [selectedLinks, setSelectedLinks] = React.useState<Set<string>>(new Set())
	const [restoreToken, setRestoreToken] = React.useState<string | null>(null)
	const [deletedCount, setDeletedCount] = React.useState(0)
	const [settingsOpen, setSettingsOpen] = React.useState(false)
	const [rootDir, setRootDir] = React.useState('')
	const [categoryDirs, setCategoryDirs] = React.useState<Record<string, string>>({})
	const [settingsMessage, setSettingsMessage] = React.useState('')
	const [downloadResult, setDownloadResult] = React.useState<DownloadResult | null>(null)
	const [serverDownloadResult, setServerDownloadResult] = React.useState<DownloadResult | null>(null)
	const [serverDownloadToastFading, setServerDownloadToastFading] = React.useState(false)
	const [searchConditions, setSearchConditions] = React.useState<SearchCondition[]>([])
	const [selectedSearchCondition, setSelectedSearchCondition] = React.useState('')
	const [refreshing, setRefreshing] = React.useState(false)
	React.useEffect(() => {
		if (!serverDownloadResult) return
		setServerDownloadToastFading(false)
		const fadeTimer = window.setTimeout(() => setServerDownloadToastFading(true), 5400)
		const removeTimer = window.setTimeout(() => setServerDownloadResult(null), 6000)
		return () => {
			window.clearTimeout(fadeTimer)
			window.clearTimeout(removeTimer)
		}
	}, [serverDownloadResult])
	React.useEffect(() => {
		let active = true
		fetch(`${base}/session`)
			.then(response => {
				if (active && response.ok) setAuthenticated(true)
			})
			.catch(() => undefined)
			.finally(() => {
				if (active) setAuthChecking(false)
			})
		return () => {
			active = false
		}
	}, [])
	React.useEffect(() => {
		if (!authenticated) return
		fetch(`${base}/search-conditions`)
			.then(response => response.ok ? response.json() as Promise<SearchCondition[]> : [])
			.then(setSearchConditions)
			.catch(() => undefined)
	}, [authenticated])
	React.useEffect(() => {
		const url = new URL(window.location.href)
		if (q) url.searchParams.set('q', q)
		else url.searchParams.delete('q')
		window.history.replaceState(null, '', url)
	}, [q])
	const params = new URLSearchParams({ q, page: String(page), page_size: String(pageSize), source })

	if (category) params.set('category', category)
	if (dateFrom) params.set('date_from', dateFrom)
	if (dateTo) params.set('date_to', dateTo)
	if (downloadedOnly) params.set('downloaded', '1')
	else if (notDownloadedOnly) params.set('not_downloaded', '1')

	const data = useQuery({
		queryKey: ['feed', params.toString()],
		enabled: authenticated,
		queryFn: async () => {
			const response = await fetch(`${base}/feed-data?${params}`)
			if (!response.ok) throw Error('取得に失敗しました')
			return response.json() as Promise<FeedResponse>
		},
	})
	const login = async (event: React.FormEvent) => {
		event.preventDefault()
		setLoginError('')
		const response = await fetch(`${base}/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ username, password }) })
		if (!response.ok) {
			setLoginError('ユーザー名またはパスワードが違います')
			return
		}
		const PasswordCredential = (window as Window & { PasswordCredential?: PasswordCredentialConstructor }).PasswordCredential
		if (window.isSecureContext && 'credentials' in navigator && PasswordCredential) {
			try {
				await navigator.credentials.store(new PasswordCredential({ id: username, password }))
			} catch {
				// Credential storage can be unavailable even after a successful login.
			}
		}
		setPassword('')
		setAuthenticated(true)
	}
	const logout = async () => {
		await fetch(`${base}/logout`, { method: 'POST' })
		setAuthenticated(false)
	}
	const refreshData = async () => {
		setRefreshing(true)
		try {
			await data.refetch()
		} finally {
			setRefreshing(false)
		}
	}
	if (authChecking) return <main className="login-page" aria-busy="true">読み込み中...</main>
	if (!authenticated) return <main className="login-page"><form className="login-form" onSubmit={login} method="post" autoComplete="on"><h2>おれたちの　あいことば</h2><label>ユーザー名<input name="username" value={username} onChange={event => setUsername(event.target.value)} onKeyDown={event => { if (event.key === 'Tab' && !username) setUsername('dankogai') }} autoComplete="username" placeholder="dankogai"/></label><label>パスワード<input name="password" type="password" value={password} onChange={event => setPassword(event.target.value)} autoComplete="current-password" placeholder="kog"/></label>{loginError && <p className="login-error">{loginError}</p>}<button type="submit">ログイン</button></form></main>
	const pages = Math.max(1, Math.ceil((data.data?.total ?? 0) / pageSize))
	const total = data.data?.total ?? 0
	const categories = data.data?.categories ?? []
	const orderedCategories = [...categoryOrder.filter(item => categories.includes(item)), ...categories.filter(item => !categoryOrder.includes(item))]
	const pageItems = data.data?.items ?? []
	const rangeStart = total === 0 ? 0 : (page - 1) * pageSize + 1
	const rangeEnd = Math.min(page * pageSize, total)
	const allPageItemsSelected = pageItems.length > 0 && pageItems.every(item => selectedLinks.has(item.link))
	const updateDateFrom = (value: string) => {
		setDateFrom(value)
		setPage(1)
	}
	const clearDateFrom = () => {
		setDateFrom('')
		setPage(1)
		setSelectedLinks(new Set())
	}
	const clearDateTo = () => {
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
		setSelectedSearchCondition('')
		clearKeyword()
		setPage(1)
		const url = new URL(window.location.href)
		if (value) url.searchParams.set('c', value)
		else url.searchParams.delete('c')
		window.history.replaceState(null, '', url)
	}
	const selectSource = (value: 'current' | 'archive') => {
		setSource(value)
		setPage(1)
		setSelectedLinks(new Set())
	}
	const searchTitle = (title: string) => {
		window.open(`https://www.google.com/search?q=${encodeURIComponent(title)}`, '_blank', 'noopener,noreferrer')
	}
	const toggleDownloadedOnly = () => {
		setDownloadedOnly(current => !current)
		setNotDownloadedOnly(false)
		setPage(1)
		setSelectedLinks(new Set())
	}
	const toggleNotDownloadedOnly = () => {
		setNotDownloadedOnly(current => !current)
		setDownloadedOnly(false)
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
	const handleDownload = async () => {
		if (!selectedLinks.size || !window.confirm(`選択した${selectedLinks.size}件をダウンロードしますか？`)) return
		try {
			const response = await fetch(`${base}/feed-data/download`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ links: Array.from(selectedLinks), source }) })
			const result = await response.json() as DownloadResult | { detail?: string }
			if (!response.ok) throw Error('detail' in result && result.detail ? result.detail : 'ダウンロードに失敗しました')
			setDownloadResult(result as DownloadResult)
			setSelectedLinks(new Set())
			await data.refetch()
		} catch (error) {
			window.alert(error instanceof Error ? error.message : 'ダウンロードに失敗しました')
		}
	}
	const handleServerDownload = async (item: Item) => {
		try {
			const response = await fetch(`${base}/feed-data/download`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ links: [item.link], source }) })
			const result = await response.json() as DownloadResult | { detail?: string }
			if (!response.ok) throw Error('detail' in result && result.detail ? result.detail : 'ダウンロードに失敗しました')
			setServerDownloadResult(current => {
				const next = result as DownloadResult
				return current ? { downloaded: [...current.downloaded, ...next.downloaded], failed: [...current.failed, ...next.failed] } : next
			})
			await data.refetch()
		} catch (error) {
			window.alert(error instanceof Error ? error.message : 'ダウンロードに失敗しました')
		}
	}
	const handleDelete = async () => {
		if (source === 'archive' || !selectedLinks.size || !window.confirm(`選択した${selectedLinks.size}件を削除しますか？`)) return
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
	const openSettings = async () => {
		setSettingsOpen(true)
		setSettingsMessage('')
		try {
			const response = await fetch(`${base}/download-settings`)
			if (!response.ok) throw Error('設定の取得に失敗しました')
			const settings = await response.json() as { root_dir: string; category_dirs: Record<string, string> }
			setRootDir(settings.root_dir)
			setCategoryDirs(settings.category_dirs)
		} catch (error) {
			setSettingsMessage(error instanceof Error ? error.message : '設定の取得に失敗しました')
		}
	}
	const saveSettings = async (event: React.FormEvent) => {
		event.preventDefault()
		try {
			const response = await fetch(`${base}/download-settings`, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ root_dir: rootDir, category_dirs: categoryDirs }) })
			if (!response.ok) throw Error('設定の保存に失敗しました')
			setSettingsMessage('保存しました')
		} catch (error) {
			setSettingsMessage(error instanceof Error ? error.message : '設定の保存に失敗しました')
		}
	}
	const saveSearchCondition = async () => {
		try {
			const response = await fetch(`${base}/search-conditions`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ category, keyword: q }) })
			if (!response.ok) throw Error('検索条件の保存に失敗しました')
			setSearchConditions(await response.json() as SearchCondition[])
		} catch (error) {
			window.alert(error instanceof Error ? error.message : '検索条件の保存に失敗しました')
		}
	}
	const applySearchCondition = (index: string) => {
		if (index === '') return
		const condition = searchConditions[Number(index)]
		if (!condition) return
		setSelectedSearchCondition(index)
		setQ(condition.keyword)
		setCategory(condition.category)
		setPage(1)
		setSelectedLinks(new Set())
		const url = new URL(window.location.href)
		if (condition.category) url.searchParams.set('c', condition.category)
		else url.searchParams.delete('c')
		window.history.replaceState(null, '', url)
	}
	const savedSearches = <div className="pagination-saved-searches"><button type="button" onClick={saveSearchCondition}>検索条件保存</button><select value={selectedSearchCondition} onChange={event => applySearchCondition(event.target.value)} aria-label="保存した検索条件"><option value="">保存した検索条件</option>{searchConditions.map((condition, index) => <option key={`${condition.category}-${condition.keyword}-${index}`} value={index}>{condition.category || 'all'}: {condition.keyword}</option>)}</select></div>
	const pagination = <div className="pagination-controls"><button disabled={page === 1} onClick={() => setPage(1)}>最初へ</button><button disabled={page === 1} onClick={() => setPage(page - 1)}>前へ</button><b>{rangeStart}-{rangeEnd} / {total}</b><button disabled={page === pages} onClick={() => setPage(page + 1)}>次へ</button><button disabled={page === pages} onClick={() => setPage(pages)}>最後へ</button><select value={pageSize} onChange={event => updatePageSize(Number(event.target.value))} aria-label="表示件数"><option value="10">10件</option><option value="20">20件</option><option value="50">50件</option><option value="100">100件</option></select></div>

	return <main>
		{serverDownloadResult && <div className={`server-download-toast${serverDownloadToastFading ? ' fading' : ''}`} role="status"><div className="toast-header"><strong>サーバー保存結果</strong><button type="button" onClick={() => setServerDownloadResult(null)} aria-label="通知を閉じる">×</button></div><p>{serverDownloadResult.downloaded.length}件保存しました。</p>{serverDownloadResult.downloaded.length > 0 && <ul>{serverDownloadResult.downloaded.map(item => <li key={`${item.category}-${item.filename}`}>{item.path}</li>)}</ul>}{serverDownloadResult.failed.length > 0 && <p className="toast-error">失敗: {serverDownloadResult.failed.map(item => item.title ?? item.link).join(', ')}</p>}</div>}
		<header>
			<div>
				<div className="title-row">
					<h2>た、種ぇぇ</h2>
					<nav className="source-links" aria-label="データソース切り替え"><button type="button" className={source === 'current' ? 'source-link active' : 'source-link'} onClick={() => selectSource('current')}>2023年-</button><button type="button" className={source === 'archive' ? 'source-link active' : 'source-link'} onClick={() => selectSource('archive')}>それ以前</button></nav>
					<nav className="category-filters" aria-label="カテゴリ絞り込み">
						<button className={category === '' ? 'category-button active' : 'category-button'} onClick={() => selectCategory('')}>all</button>
						{orderedCategories.map(item => <button key={item} className={`category-button${pinkCategories.has(item) ? ' pink-category' : ''}${category === item ? ' active' : ''}`} onClick={() => selectCategory(item)}>{item}</button>)}
					</nav>
				</div>
			</div>
		</header>
		<div className="search-row">
		<div className="search">
			<Search size={18}/>
			<input value={q} onChange={event => { setQ(event.target.value); setPage(1) }} placeholder="Search..."/><button className="clear-keyword" onClick={clearKeyword} aria-label="検索キーワードを全消去">×</button>
			<span className="date-range-label">取得日時</span>
			<div className="date-range">
				<label className="date-field"><span>開始日</span><span className={dateFrom ? 'date-input date-display' : 'date-input date-display empty'} onClick={() => { const input = dateFromPickerRef.current; if (!input) return; try { input.showPicker?.() } catch { input.click() } }}>{dateFrom || 'YYYY-MM-DD'}</span><button className="date-clear" type="button" onClick={clearDateFrom} aria-label="開始日をクリア" title="開始日をクリア">×</button><input ref={dateFromPickerRef} className="date-picker" type="date" value={dateFrom} onChange={event => updateDateFrom(event.target.value)} aria-label="取得日時の開始日"/></label>
				<span>～</span>
				<label className="date-field"><span>終了日</span><span className={dateTo ? 'date-input date-display' : 'date-input date-display empty'} onClick={() => { const input = dateToPickerRef.current; if (!input) return; try { input.showPicker?.() } catch { input.click() } }}>{dateTo || 'YYYY-MM-DD'}</span><button className="date-clear" type="button" onClick={clearDateTo} aria-label="終了日をクリア" title="終了日をクリア">×</button><input ref={dateToPickerRef} className="date-picker" type="date" value={dateTo} onChange={event => { setDateTo(event.target.value); setPage(1) }} aria-label="取得日時の終了日"/></label>
			</div>
		</div>
		<div className="session-toolbar"><button onClick={refreshData} aria-label="一覧を更新" title="一覧を更新" disabled={refreshing}><RefreshCw className={refreshing ? 'refreshing' : ''} size={16}/></button><button onClick={logout} aria-label="ログアウト" title="ログアウト"><LogOut size={16}/></button></div>
		</div>
		<div className="pagination pagination-top">{savedSearches}{pagination}</div>
		{restoreToken && <div className="undo-banner">{deletedCount}件削除しました<button onClick={handleRestore}>元に戻す</button></div>}
		<section>
			<div className="table-toolbar"><button className="download-settings-link" type="button" onClick={openSettings}>ダウンロード先設定</button><button className="action-download" disabled={!selectedLinks.size} onClick={handleDownload}>一括ダウンロード</button><button className="action-delete" disabled={source === 'archive' || !selectedLinks.size} onClick={handleDelete}>削除</button><button className={notDownloadedOnly ? 'action-downloaded action-downloaded-group active' : 'action-downloaded action-downloaded-group'} onClick={toggleNotDownloadedOnly}>未DL</button><button className={downloadedOnly ? 'action-downloaded active' : 'action-downloaded'} onClick={toggleDownloadedOnly}>DL済み</button></div>
			{data.isLoading ? '読み込み中...' : data.isError ? '取得に失敗しました' : <table>
				<thead><tr><th className="select-column"><input type="checkbox" checked={allPageItemsSelected} onChange={event => togglePageSelection(event.target.checked)} aria-label="このページの全行を選択"/></th><th>カテゴリ</th><th>タイトル</th><th>URL</th><th>取得日時</th><th className="download-column">DL</th></tr></thead>
				<tbody>{data.data?.items.map(item => <tr key={item.link} className={selectedLinks.has(item.link) ? 'selected' : ''} onClick={() => toggleSelected(item.link)}>
					<td className="select-column"><input type="checkbox" checked={selectedLinks.has(item.link)} onChange={() => toggleSelected(item.link)} onClick={event => event.stopPropagation()} aria-label={`${item.title}を選択`}/></td>
					<td><button type="button" className={pinkCategories.has(item.category) ? 'category-tag pink-category-tag' : 'category-tag'} onClick={event => { event.stopPropagation(); selectCategory(item.category) }}>{item.category}</button></td>
					<td className="title-column"><span className="title-content"><button type="button" className="title-search" title="Googleで検索" aria-label={`${item.title}をGoogleで検索`} onClick={event => { event.stopPropagation(); searchTitle(item.title) }}>G</button><b>{item.title}</b></span></td>
					<td><span className="download-actions"><a className="download-link" href={item.link} aria-label={`${item.title}をダウンロード`} title="ブラウザでダウンロード" onClick={event => event.stopPropagation()}><Download size={16}/></a><button type="button" className="server-download-link" aria-label={`${item.title}をサーバーに保存`} title="サーバーに保存" onClick={event => { event.stopPropagation(); handleServerDownload(item) }}><HardDriveDownload size={16}/></button></span></td>
					<td className="date-column">{formatCreatedAt(item.created_at)}</td>
					<td className="download-status" title={item.download_dir ?? undefined}>{item.download_dir ? '○' : ''}</td>
				</tr>)}</tbody>
			</table>}
		</section>
		{settingsOpen && <div className="settings-backdrop" role="presentation"><div className="settings-modal" role="dialog" aria-modal="true" aria-labelledby="settings-title"><div className="settings-header"><h2 id="settings-title">ダウンロード先設定</h2><button type="button" onClick={() => setSettingsOpen(false)} aria-label="設定を閉じる">×</button></div><form onSubmit={saveSettings} className="settings-form"><label>ルートディレクトリ<input value={rootDir} onChange={event => setRootDir(event.target.value)} /></label><fieldset><legend>カテゴリ別保存ディレクトリ</legend>{downloadCategories.map(item => <label className="category-setting-row" key={item}><span className={`category-button${pinkCategories.has(item) ? ' pink-category' : ''}`}>{item}</span><input value={categoryDirs[item] ?? ''} onChange={event => setCategoryDirs(current => ({ ...current, [item]: event.target.value }))} /></label>)}</fieldset><div className="settings-actions"><button type="submit">保存</button>{settingsMessage && <span>{settingsMessage}</span>}</div></form></div></div>}
		{downloadResult && <div className="settings-backdrop" role="presentation"><div className="download-result-modal" role="dialog" aria-modal="true" aria-labelledby="download-result-title"><div className="settings-header"><h2 id="download-result-title">ダウンロード結果</h2></div><p>{downloadResult.downloaded.length}件ダウンロードしました。</p>{downloadResult.downloaded.length > 0 && <ul>{downloadResult.downloaded.map(item => <li key={`${item.category}-${item.filename}`}>{item.path}</li>)}</ul>}{downloadResult.failed.length > 0 && <><h3>失敗</h3><ul>{downloadResult.failed.map(item => <li key={item.link}>{item.title ?? item.link}: {item.reason}</li>)}</ul></>}<div className="settings-actions"><button type="button" onClick={() => setDownloadResult(null)}>OK</button></div></div></div>}
		<footer className="pagination pagination-bottom">{pagination}</footer>
	</main>
}

createRoot(document.getElementById('root')!).render(<QueryClientProvider client={client}><App/></QueryClientProvider>)
