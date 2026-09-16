# Torrent Feed Admin

SQLite の `nyaatorrent_feed.db` を検索・編集する管理画面です。

## Local setup

Node.js 20+ と Python 3.11+ を用意します。

```sh
cd web
python -m venv .venv
. .venv/bin/activate       # Windows PowerShell: .venv\\Scripts\\Activate.ps1
pip install -r requirements.txt
npm install
```

APIとフロントエンドを別ターミナルで起動します。

```sh
uvicorn api:app --reload --port 8000
npm run dev
```

ブラウザで http://127.0.0.1:5173/ を開きます。

## Production shape

```sh
npm run build
uvicorn api:app --host 127.0.0.1 --port 8000
```

`dist/` は httpd で配信し、`/api/` だけを `127.0.0.1:8000` へリバースプロキシします。DBファイルはWeb公開ディレクトリの外に置き、APIも外部ポートへ直接公開しません。

サブパスで配信する場合は、ビルド時にベースパスを指定します。

```sh
VITE_BASE_PATH=/torrent-admin/ npm run build
```

```apache
ProxyPass        /torrent-admin/api/ http://127.0.0.1:8000/api/
ProxyPassReverse /torrent-admin/api/ http://127.0.0.1:8000/api/
Alias /torrent-admin/ /path/to/web/dist/
<Directory /path/to/web/dist/>
    Require all granted
</Directory>
```

フロントエンドをサブパスで配信する場合は、Viteの `base` を `/torrent-admin/` に設定してください。実環境では必ずhttpd側の認証・IP制限・HTTPSを追加し、更新操作の監査ログも運用前に検討してください。
