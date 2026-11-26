# E. 導入の準備（setup）

キットを使い始めるための準備です。1人あたり30分ほどを見込んでください。

## 1. 必要なもの

| もの | 用途 | 備考 |
|---|---|---|
| Git とこのリポジトリ | ルール・素材・スキルの置き場 | 導入先のリポジトリにコピーしてもよい |
| Claude Code | AIで画面を作る・レビューする | `.claude/` の CLAUDE.md・PROTOTYPE.md・スキルを自動で読む |
| Figma（編集の席） | 素材の正本（ライブラリ） | ライブラリの公開とブランチが使えるプラン |
| Figma デスクトップアプリ | Figma MCP（ローカル） | 画面の読み取りに使う |
| Node.js | 確認用の簡易サーバー（`tools/serve.js`） | 任意 |
| PowerShell | `prototype-share-html` | Windows は標準。macOS は `pwsh` を入れる（任意） |

## 2. リポジトリを開く

```bash
git clone <このリポジトリのURL>
cd ai-design-kit
claude
```

Claude Code をリポジトリの直下で起動すると、`.claude/CLAUDE.md` と `.claude/skills/` が読み込まれます。

## 3. Figma MCP をつなぐ

このリポジトリの `.mcp.json` には、次の2つが登録されています。

| 名前 | つなぎ先 | 用途 |
|---|---|---|
| `Figma` | `http://127.0.0.1:3845/mcp`（デスクトップアプリ） | 選択中の画面・部品の読み取り |
| `figmaRemoteMcp` | `https://mcp.figma.com/mcp` | ファイルの読み取り・書き込み（`use_figma`） |

1. Figma デスクトップアプリで、MCP サーバーを有効にする（Figma の公式の手順に従う）。
2. Claude Code で `/mcp` を開き、`figmaRemoteMcp` の認証を行う。
3. Claude Code に「Figma の `<ファイルURL>` の Components ページの部品を一覧にして」と頼み、読み取れることを確かめる。

## 4. Figma の公式スキルを入れる

Figma への書き込み（`use_figma`）を使うスキル（`design-system-measure`・`design-system-apply-fixes`・`prototype-to-figma` など）は、Figma 公式のスキル `figma-use`（と、ライブラリを作るときは `figma-generate-library`）を前提にしています。
このキットには含めていないので、**Figma 公式の Claude Code 用プラグイン**を入れてください（入れ方は Figma のドキュメントに従う）。

## 5. 導入先に合わせて書き換える場所

| ファイル | 書き換えること |
|---|---|
| `.claude/CLAUDE.md` | サービス名（`<service>`）の一覧、生成物の置き場所 |
| `guidelines/design-system-map.md` | Figma の fileKey・ページ・node の所在 |
| `guidelines/kit/DESIGN.md` | 1章（雰囲気・利用者・画面サイズ）。値はスキルで同期する |
| `guidelines/rules/*.md` | `<…>` の欄（許可語・業務の軸など）。導入先で合意してから正式版にする |
| `docs/B_design-rules/ux-principles.md` | 4-2 提出基準 |
| `.claude/skills/accessibility-review/SKILL.md` | サービスごとの必達／推奨／適用外の表 |
| `docs/B_design-rules/maintenance.md` | 1章の更新責任者 |

## 6. 動作の確認

| 確かめること | やり方 |
|---|---|
| 素材の見本が表示される | `node tools/serve.js` を起動し、`http://localhost:8765/guidelines/kit/components-showcase.html` を開く |
| スキルが呼べる | Claude Code で「スキルの一覧を見せて」と頼む |
| Figma が読める | 3章の3 |
