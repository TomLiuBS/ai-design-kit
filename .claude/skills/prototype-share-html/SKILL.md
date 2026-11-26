---
name: prototype-share-html
description: "generated/prototypes/ のプロトタイプを、GitHubにアクセスできない人へ渡すための単体HTML（1ファイル）にして、実行したユーザーのデスクトップに保存するスキル。CSS・JS・アイコン画像をすべて1つのHTMLに埋め込むので、そのHTMLを渡してダブルクリックで開くだけで見た目が崩れずに動く。使用時：「プロトタイプをHTMLにして」「共有用HTMLを作って」「単体HTMLにして」「GitHubを使えない人に渡したい」と言われた時。"
---

# prototype-share-html スキル

プロトタイプ1つを、**単体で動くHTML 1ファイル**にして**デスクトップ**に保存する。
プロトタイプの `index.html` は `../../../../../guidelines/...` のCSSや `prototype.js`、`assets/` の画像を相対パスで読むため、`index.html` だけ渡すと相手の環境で見た目が崩れる。このスキルは参照先をすべてHTMLの中に埋め込む。

**実行環境: Windows / PowerShell 前提**のスクリプト（`make-html.ps1`）で動く。macOS では PowerShell（`pwsh`）がインストールされていれば、手順3の `powershell` を `pwsh` に読み替えて実行する（パスの区切りは `/` でよい）。`pwsh` が無い場合は、インストールするかどうかをユーザーに確認する。

## 手順

1. **対象を決める。** 依頼にプロトタイプ名（`generated/prototypes/<service>/<プロト名>/<バージョンのフォルダ名>`）がなければ、`generated/prototypes/` の3階層目までの一覧を示して**どれか質問する**。推測で選ばない。
2. **ファイル名を決める。** ファイル名は、プロトタイプの**メインの画面名を英語にしたもの**にする（例: `request-list`）。英小文字・数字・`-` のみ。
   - 基本は、フォルダ名 `<画面名>_<施策名>` の `<画面名>` の部分を使う。
   - メインの画面が複数ある、フォルダ名と画面の内容が合わない、英語名に迷う、のいずれかなら、候補を示して**ユーザーに質問する**。推測で決めない。
3. **スクリプトを実行する。** リポジトリのルートで、次を実行する（`<name>` は `<service>/<プロト名>/<バージョンのフォルダ名>`（バージョンのフォルダ名だけでも、一意なら可）、`<file>` は手順2で決めたファイル名）。

   ```powershell
   powershell -NoProfile -File .claude\skills\prototype-share-html\make-html.ps1 -Name <name> -OutName <file>
   ```

   macOS（`pwsh` がある場合）:

   ```bash
   pwsh -NoProfile -File .claude/skills/prototype-share-html/make-html.ps1 -Name <name> -OutName <file>
   ```

4. **出力を読んで報告する。** スクリプトは次を表示する。
   - `HTML:` 作成したHTMLの場所（デスクトップ。OneDriveにリダイレクトされていても正しい場所になる）
   - `Size:` ファイルの大きさ
   - `Embedded files:` 埋め込んだファイルの数
   - `WARNINGS:` 埋め込めなかった参照（あれば）。警告があるときは、見た目や動作が崩れる可能性をユーザーに伝え、該当ファイルを確認する。
5. **HTMLの場所をユーザーに伝える。** 開くコマンドも添える。

   ```powershell
   explorer /select,"<HTMLのフルパス>"
   ```

   macOS の場合:

   ```bash
   open -R "<HTMLのフルパス>"
   ```

6. **渡し方を伝える。**
   - HTMLファイルをそのまま渡せばよい（展開は不要）。メール添付やチャットへのアップロードでも、ブラウザにドラッグして開ける。
   - フォントとアイコンはGoogle Fontsから読むため、ネットにつながる環境が必要。

## スクリプトの動き

- 出力名は `<file>_<YYYYMMDD>.html`（`-OutName` を省略するとフォルダ名）。同名があれば上書きせず `-2`、`-3` を付ける。
- `index.html` の次を埋め込む。
  - `<link rel="stylesheet" href="（ローカル）">` → `<style>`（`../` で始まるDSのCSSも対象）
  - `<script src="（ローカル）"></script>` → インライン `<script>`
  - `src` / `href` が指すローカル画像（svg, png, jpg, gif, webp, woff2 など）→ `data:` URI
- CSSの `url(...)` とJSの文字列にあるローカル画像のパスも `data:` URI にする。
- JSのパスに `${...}` が含まれる場合（例: `assets/stamps/stamp-${n}.png`）は、該当ファイルをすべて `window.__ASSETS` に入れ、JS内の参照を `__ASSETS[...]` に置き換える。
- `https://` で始まる外部参照（Google Fontsなど）は、そのまま残す。
- リポジトリは変更しない。`-OutDir <フォルダ>` を付けると、出力先をデスクトップ以外にできる（検証用）。

## 注意

- HTMLはデスクトップに保存する。リポジトリの `generated/` には保存しない（GitHubには上げない）。
- 埋め込み済みのHTMLは生成物。修正は元のプロトタイプのフォルダで行い、共有するたびに作り直す。
- 開いて見た目と主要な操作を確認してから渡すよう、ユーザーに勧める。
- JSの中で文字列を組み立ててパスを作っている場合（`'assets/' + name + '.png'` など）は、自動では埋め込めない。警告は出ないので、動作確認で画像が出ないときはここを疑う。
- スクリプトはASCIIのみで書く（Windows PowerShell 5.1がBOMなしのUTF-8をANSIとして読むため）。メッセージを日本語にしない。
