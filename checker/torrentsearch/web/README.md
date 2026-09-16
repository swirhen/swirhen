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

本番APIは付属の `torrent-admin-api.service` をsystemdへ登録して起動します。

```bash
cd /home/swirhen/sh/checker/torrentsearch/web
sudo install -m 0644 torrent-admin-api.service /etc/systemd/system/torrent-admin-api.service
sudo systemctl daemon-reload
sudo systemctl enable --now torrent-admin-api.service
sudo systemctl status torrent-admin-api.service
curl http://127.0.0.1:8000/api/health
```

ログ確認:

```bash
sudo journalctl -u torrent-admin-api.service -f
```

ソースやビルドを更新した場合:

```bash
VITE_BASE_PATH=/torrent-admin/ npm run build
sudo systemctl restart torrent-admin-api.service
sudo systemctl reload apache2
```
