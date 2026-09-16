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

ローカルで管理画面を起動する場合:

```powershell
cd web
$env:Path = "C:\Program Files\nodejs;$env:Path"
npm run dev
```

本番APIは付属の `torrent-admin-api.service` をsystemdへ登録して起動します。

API認証用の環境ファイルを実環境に作成します。値はGitへ登録しません。

```bash
sudo install -m 0600 /dev/null /etc/default/torrent-admin-api
sudo sh -c 'cat > /etc/default/torrent-admin-api <<EOF
TORRENT_ADMIN_USERNAME=dankogai
TORRENT_ADMIN_PASSWORD=変更してください
TORRENT_ADMIN_SECRET=十分に長いランダムな秘密文字列
EOF'
```

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

実環境でgit pull後にフロントエンドの再ビルドとAPI再起動をまとめて行う場合:

```bash
cd /home/swirhen/sh/checker
git pull --ff-only
cd torrentsearch/web
chmod +x release.sh
./release.sh
```
