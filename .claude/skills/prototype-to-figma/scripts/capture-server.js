// プロトタイプをFigmaへキャプチャするための一時サーバー（リポジトリのファイルは変更しない）
// 使い方: node capture-server.js <リポジトリルート> [--port 8791] [--width 1024] [--height 768]
// 配信するHTMLにだけ、次の3つを差し込む。
//   1. Figmaのキャプチャスクリプト
//   2. 画面幅の固定（既定1024px。ウィンドウ幅に左右されない）
//   3. アイコンフォント（Material Symbols）の箱を1em四方に固定（フォント読込前の文字幅が
//      レイアウトに入るのを防ぐ）
const http = require('http'), fs = require('fs'), path = require('path');

const args = process.argv.slice(2);
const root = path.resolve(args[0] || '.');
const opt = (name, def) => { const i = args.indexOf('--' + name); return i >= 0 ? args[i + 1] : def; };
const port = +opt('port', 8791), width = +opt('width', 1024), height = +opt('height', 768);

const types = {
  '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript',
  '.svg': 'image/svg+xml', '.png': 'image/png', '.json': 'application/json',
  '.md': 'text/plain; charset=utf-8',
};
const inject =
  `<style>html,body{width:${width}px;max-width:${width}px;overflow-x:hidden}` +
  `.app{height:${height}px!important}` +
  `.material-symbols-outlined{display:inline-block;width:1em;height:1em;overflow:hidden;white-space:nowrap;line-height:1}</style>` +
  `<script src="https://mcp.figma.com/mcp/html-to-design/capture.js" async></script>`;

http.createServer((req, res) => {
  const p = path.join(root, decodeURIComponent(req.url.split('?')[0].split('#')[0]));
  if (!p.startsWith(root)) { res.writeHead(403); return res.end(); }
  fs.readFile(p, (e, d) => {
    if (e) { res.writeHead(404); return res.end('not found'); }
    res.writeHead(200, { 'Content-Type': types[path.extname(p)] || 'application/octet-stream' });
    if (p.endsWith('.html')) d = Buffer.from(d.toString('utf8').replace('</head>', inject + '</head>'));
    res.end(d);
  });
}).listen(port, () => console.log(`listening http://localhost:${port}/ (root=${root}, ${width}x${height})`));
