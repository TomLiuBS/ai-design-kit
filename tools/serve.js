// プロトタイプ確認用の簡易サーバー（リポジトリ直下を配信する）。使い方: node tools/serve.js → http://localhost:8765/<パス>
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8765;
const ROOT = path.resolve(__dirname, '..');
const TYPES = {
  '.html': 'text/html;charset=utf-8', '.css': 'text/css', '.js': 'text/javascript',
  '.svg': 'image/svg+xml', '.png': 'image/png', '.json': 'application/json'
};

const server = http.createServer((req, res) => {
  const file = path.join(ROOT, decodeURIComponent(req.url.split('?')[0]));
  if (!file.startsWith(ROOT)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
});

server.on('error', (e) => {
  if (e.code === 'EADDRINUSE') console.log(`ポート ${PORT} は使用中です。すでにサーバーが動いているので、そのまま使えます。`);
  else console.log(e.message);
});
server.listen(PORT, '127.0.0.1', () => console.log(`起動しました: http://localhost:${PORT}/ （止めるときは Ctrl+C かこのウィンドウを閉じる）`));
