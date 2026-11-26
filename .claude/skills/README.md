# Claude スキル一覧

このキットに含まれる Claude Code のスキルです。`.claude/skills/` に置くと Claude Code が自動で認識し、依頼の言葉（下の「こんな時に」）に応じて呼び出します。
保存先・命名・用語は [../CLAUDE.md](../CLAUDE.md)、プロトタイプのルールは [../PROTOTYPE.md](../PROTOTYPE.md) が基準です。

---

## つなぎ方（実行する順番）

```
① ルール        design-rules-editor ／ component-authoring-advisor
                    ↓（guidelines/rules/ が決まる）
② 同期          figma-guideline-sync → figma-components-css-sync → design-system-generate
                    ↓（guidelines/kit/ ができる）
③ DS品質        design-system-measure → design-system-audit-skill → 人の承認
                    → design-system-apply-fixes → 再実測（design-system-measure）
                 ＋ ds-fix-memo（ルールには合うが中身がずれている所の記録）
                    ↓
④ プロトタイプ  prototype-draft → prototype-share-html → prototype-to-figma
                    ↓
⑤ 画面レビュー  figma-ai-review ／ figma-review-layers ／ figma-rename-layers ／
                 design-production-readiness ／ figma-ui-review ／ accessibility-review
```

- ②の3つは必ずこの順番で実行します（トークン → 部品のCSS → 説明文書）。
- ③で Figma を書き換えるのは `design-system-apply-fixes` だけです。DSレビューの修正案は、人が承認した項目だけを実行します。
- ⑤は目的に応じて単独で使います（順番の決まりはありません）。

---

## スキル一覧

### ① ルール

| スキル | 何をするか | こんな時に |
|---|---|---|
| `design-rules-editor` | `guidelines/rules/` のルール文書（レイヤー名・Variant名・Description・Component作成・Variables）を点検・追記・修正・新設する。ルールの中身を人に代わって決めない。 | 「ルールを追加して」「R-XXを修正して」「このルール案を点検して」「ルール同士の矛盾を確認して」 |
| `component-authoring-advisor` | Component / Component Set を作る・更新するときの相談役（CA-00〜CA-10 ほか）。Figmaには書き込まない。 | 「これはComponent化すべき？」「軸をどう設計する？」「複数版があるがどちらが正本？」 |

### ② 同期（Figma → `guidelines/kit/`）

| スキル | 何をするか | こんな時に |
|---|---|---|
| `figma-guideline-sync` | FigmaのガイドラインからDESIGN.md・design-tokens.json / .css を更新する。 | 「ガイドラインを更新して」「Figmaのガイドラインをローカルに反映して」 |
| `figma-components-css-sync` | Figmaの共通・サービス固有コンポーネントから components.css を生成・更新する。 | 「components.cssを更新して」「Figmaのコンポーネントをcomponents.cssに反映して」 |
| `design-system-generate` | トークンとCSSを読み、共通の DESIGN.md、またはサービス固有の design-system.md を書く。 | 「デザインシステムを更新して」「DESIGN.mdを最新化して」 |

### ③ DS品質（AI-ready）

| スキル | 何をするか | こんな時に |
|---|---|---|
| `design-system-measure` | DSの数値指標を、固定の範囲・形式で実測する（読み取り専用。判定しない）。 | 「DSの実測値を出して」「ベースラインを測って」「Before/Afterの数値を出して」 |
| `design-system-audit-skill` | DSがAIに読み込める形かを9カテゴリでDSレビューし、根拠付きの評価と修正リストを出す（Figmaは変えない）。起動前にモデル確認あり（CLAUDE.md）。 | 「デザインシステムをレビューして」「AI-ready評価をして」「承認した改善を再レビューして」 |
| `design-system-apply-fixes` | 承認済みの修正項目だけを、既定で検証用ブランチのFigmaへ書き込む（2段階承認）。 | 「DSレビューで出た修正を反映して」「#8を直して」 |
| `ds-fix-memo` | ルールには合うが中身・意味がずれている所と、FigmaのDSに無くCSSへ暫定追加した部品を、修正メモに記録する。 | 「修正メモに追加して」「FX-001を修正済みにして」「修正メモの一覧を見せて」 |

### ④ プロトタイプ

| スキル | 何をするか | こんな時に |
|---|---|---|
| `prototype-draft` | Epic/Feature/画面骨子から、PROTOTYPE.md に沿ってHTMLプロトタイプを作り、その場で軽量レビューする（差し戻しは上限2回）。 | 「ハーネスに従ってプロトタイプを作って」「画面骨子から作って」 |
| `prototype-share-html` | プロトタイプを、CSS・JS・画像を埋め込んだ単体HTML（1ファイル）にする。Windows / PowerShell 前提（macOS は `pwsh` があれば実行可）。 | 「プロトタイプをHTMLにして」「共有用HTMLを作って」「GitHubを使えない人に渡したい」 |
| `prototype-to-figma` | プロトタイプをpx単位でFigmaに書き起こし、DSのコンポーネントに置き換える。DSに無い部品は一覧にする。 | 「プロトタイプをFigmaにして」「プロトタイプをFigmaに書き起こして」 |

### ⑤ 画面レビュー

| スキル | 何をするか | こんな時に |
|---|---|---|
| `figma-ai-review` | 画面ファイルがAI駆動開発に適した作りかを8項目で審査し、スコアカードを出す。 | 「AI駆動開発に適しているかレビューして」「AI観点でFigmaを審査して」 |
| `figma-review-layers` | レイヤー名を命名ルールでレビューし、違反と修正案を出す（指示があるときだけ変更）。 | 「レイヤー名をチェックして」「命名ルールに違反しているレイヤーを直して」 |
| `figma-rename-layers` | 画面要件書のタイトル番号（例：3.1.1.1）を、Figmaのレイヤー名の冒頭に付ける。 | 「要件書の番号をFigmaのレイヤーに反映して」 |
| `design-production-readiness` | ラフ→本デザインの前（フェーズ1）と実装前（フェーズ2）に、抜けもれを8カテゴリで確認し、TODOを出す。 | 「本デザインに移る前に確認して」「実装前のチェックをして」 |
| `figma-ui-review` | WCAG・Material Design・Apple HIG などに基づき、画面の見た目と構造の品質をスコアで評価する。 | 「このデザインをレビューして」「このUIをチェックして」 |
| `accessibility-review` | サービスごとに決めた基準（必達/推奨/適用外）で、WCAG A/AA/AAA を評価する。サービス名が必要。 | 「<サービス名>のアクセシビリティチェックをして」「WCAGに準拠しているか確認して」 |

---

## 別途インストールするスキル

`figma-use`（Figma をコードで操作するための前提スキル）と `figma-generate-library`（Figmaにデザインシステムを構築する）は、Figma 公式のスキルです。このキットには含めていません。インストール手順は [docs/E_handover/setup.md](../../docs/E_handover/setup.md) を参照してください。`use_figma` を使うスキル（`design-system-apply-fixes`・`prototype-to-figma` など）は、`figma-use` を読み込んでから動きます。

---

## スキルを更新するには

キットのリポジトリを取得し直す（`git pull`）と、`.claude/skills/` の内容が更新されます。スキルの中身を変えたときは、このREADMEの一覧とつなぎ方も合わせて直してください。
