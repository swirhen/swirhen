# Torrent Feed Admin

```powershell
cd web
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
$env:Path = "C:\Program Files\nodejs;$env:Path"
npm install
npm run build
```

別ターミナルでAPIを起動します。

```powershell
cd web
.venv\Scripts\python.exe -m uvicorn api:app --reload --port 8000
```

開発サーバーは `npm run dev`。本番は `VITE_BASE_PATH=/torrent-admin/ npm run build` とし、httpdで `dist/` を配信、`/torrent-admin/api/` を `http://127.0.0.1:8000/api/` へProxyPassします。
