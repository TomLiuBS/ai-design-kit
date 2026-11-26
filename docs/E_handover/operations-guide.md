# E. 運用ガイド

キットを引き継いだあと、**日々どう使い、何に気をつけるか**をまとめました。準備は [setup.md](setup.md)、更新の手順は [update-procedure.md](update-procedure.md)。

---

## 1. 日々の使い方

### 1-1. 画面を作る（いちばん多い作業）

1. [入力テンプレート](../B_design-rules/process.md#2-入力テンプレート)で Epic／Feature／画面骨子を書く。
2. Claude Code に「ハーネスに従ってプロトタイプを作って」と頼み、骨子を渡す（`prototype-draft` スキルが動く）。
3. AIからの質問（不足している情報・素材にない部品）にまとめて答える。
4. 初版ができたらコミットする。
5. 画面レビュー（ツールの実測＋目視）で提出基準を確かめる。
6. 指摘を直す。「素材に不足」の報告は、修正メモ（`generated/docs/ds-content-fix-memo.md`）に残す。

### 1-2. ほかの人に見せる

| したいこと | 頼み方 | スキル |
|---|---|---|
| Git を使わない人に渡す | 「共有用HTMLを作って」 | `prototype-share-html` |
| Figma に書き起こす | 「プロトタイプをFigmaに書き起こして」 | `prototype-to-figma` |

### 1-3. 画面をレビューする

| 目的 | スキル |
|---|---|
| Figma の画面ファイルが AI で扱いやすい作りか | `figma-ai-review` |
| レイヤー名がルールに沿っているか | `figma-review-layers` |
| 見た目の品質（整列・余白・色・文字） | `figma-ui-review` |
| アクセシビリティ | `accessibility-review` |
| 本デザインに進める・実装に渡せる状態か | `design-production-readiness` |

---

## 2. スキルのつなぎ方

```
① ルール        design-rules-editor ／ component-authoring-advisor
② 同期          figma-guideline-sync → figma-components-css-sync → design-system-generate
③ 素材の品質    design-system-measure → design-system-audit-skill → 人の承認
                 → design-system-apply-fixes → design-system-measure（再実測）
                 ＋ ds-fix-memo
④ プロトタイプ  prototype-draft → prototype-share-html → prototype-to-figma
⑤ 画面レビュー  figma-ai-review ／ figma-review-layers ／ figma-rename-layers ／
                 design-production-readiness ／ figma-ui-review ／ accessibility-review
```

各スキルの説明と呼び出す言葉は [.claude/skills/README.md](../../.claude/skills/README.md)。

---

## 3. 注意点

| 注意点 | 理由 |
|---|---|
| **推測で埋めさせない** | 素材にない部品をAIが作り込むと、品質がぶれ、素材を育てる報告も出なくなる |
| **Figma の修正は検証用ブランチで** | `design-system-apply-fixes` は既定でブランチに書く。本体へのマージとライブラリの公開は人が行う |
| **判定と修正を分ける** | 実測（数える）・DSレビュー（何を直すか決める）・修正（直す）を1つの依頼でまとめてさせない |
| **DSレビューは推奨モデルで** | `design-system-audit-skill` は Sonnet 5.5 で結果をそろえている。モデルを変えたらレポートに書く |
| **同期は人が指示したときだけ** | 画面を作るたびに Figma と同期しない（時間とコストがかかり、結果も比べにくくなる） |
| **会話を分ける** | 画面づくりと、共有・環境設定・相談は別の会話で。長くなったら `NOTES.md` に書いて新しい会話に移る |
| **AIに入れる情報に気をつける** | 個人情報・機密は、導入先の決まりに従って入力しない |
| **点数は改善のため** | 画面の点数は個人の評価に使わない |
| **既存のファイルは上書きしない** | 修正版は `-v2` のように版を付ける。上書きするか新しい版にするかは、作業の前に依頼者が決める |

---

## 4. 困ったとき

| 困りごと | まず見る所 |
|---|---|
| AIが素材と違う見た目を作る | `component-map.md` にその部品があるか、確認日が30日以内か |
| 同じ指摘が繰り返される | ルールか素材に足すべき論点か（[maintenance.md](../B_design-rules/maintenance.md) 5章） |
| Figma が読めない | `/mcp` の接続、Figma デスクトップアプリの MCP の設定（[setup.md](setup.md)） |
| ルール同士が食い違う | `design-rules-editor` に「ルール同士の矛盾を確認して」と頼む |
| どのスキルを使えばよいか分からない | Claude Code に「スキルの一覧を見せて」と頼む |
