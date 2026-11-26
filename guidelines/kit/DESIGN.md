# DESIGN.md（共通デザインシステム）— テンプレート

> **状態：枠組みのみ（値は仮）**。導入先で Figma ライブラリを作ったら、`design-system-generate` スキル（モード A）でこのファイルを上書きします。
> ソース：Figma `<共通DSのfileKey>`（所在は [../design-system-map.md](../design-system-map.md)）／`design-tokens.css`／`components.css`
> 版：v0.1（仮）　最終同期：`<YYYY-MM-DD>`

---

## 0. このファイルの使い方

- AI（Claude Code など）は画面を作る前にこのファイルを読み、**判断のルール**として使う。値そのものは `design-tokens.css`、部品の実装は `components.css`、部品の索引は `component-map.md` を見る。
- 見た目の正本は Figma ライブラリ。このファイルと Figma が食い違ったら Figma に合わせ、修正メモに記録する。
- ここに書かれていない部品・挙動は、推測で作らずに「素材に不足」として報告する。

## 1. Visual Theme & Atmosphere

| 項目 | 記入欄 |
|---|---|
| ひとことで | `<例：落ち着いて、正確で、少し温かい>` |
| 利用者 | `<例：社内の業務担当、月に数回使う>` |
| 主な画面サイズ | `<例：PC 1366×768、最小幅 1024px>` |
| 避けたい印象 | `<例：派手な色づかい、装飾の多い影>` |

## 2. カラーパレット

| 役割 | トークン | 値（仮） | 使いどころ | 使わないところ |
|---|---|---|---|---|
| 主色 | `--color-primary` | 仮 | 主ボタン、選択中、リンク | 広い背景 |
| 文字 | `--color-text` / `--color-text-sub` / `--color-text-muted` | 仮 | 本文／補足／注記 | — |
| 面 | `--color-bg` / `--color-surface` / `--color-surface-raised` | 仮 | 画面の背景／カード／入力欄・選択行 | — |
| 線 | `--color-border` | 仮 | 区切り線、入力欄の枠 | — |
| 意味色 | `--color-success` / `--color-warning` / `--color-error` / `--color-info` | 仮 | 結果・状態の表示 | 装飾 |

- 文字と背景の組み合わせは、コントラスト 4.5:1 以上になる組み合わせだけを使う（組み合わせ表を `<ここ>` に置く）。
- 意味色は、意味があるときだけ使う。色だけで意味を伝えず、文字やアイコンを添える。

## 3. タイポグラフィ

| トークン | サイズ（仮） | 行間 | 太さ | 用途 |
|---|---|---|---|---|
| `--font-size-heading-l` | 仮 | 仮 | 仮 | 画面のタイトル |
| `--font-size-heading-m` | 仮 | 仮 | 仮 | 見出し |
| `--font-size-heading-s` | 仮 | 仮 | 仮 | 小見出し・カードの見出し |
| `--font-size-body-l` | 仮 | 仮 | 仮 | 強めの本文 |
| `--font-size-body-m` | 仮 | 仮 | 仮 | 本文・ボタン |
| `--font-size-body-s` | 仮 | 仮 | 仮 | 補足 |
| `--font-size-caption` | 仮（12px 以上） | 仮 | 仮 | 注記・ラベル |

- 書体：`<和文>`／`<欧文>`／`<数字用（任意）>`
- 太さは2〜3段階まで。階層は大きさと色で作る。

## 4. スペーシング

- 4px を基準に、`--space-1`（4）〜`--space-16`（64）の段階を使う。
- 部品の内側 4〜12、関連する要素の間 8、グループの間 16〜24、セクションの間 32〜64。
- 同じ種類の要素には同じ余白を使う（一覧の行、同じ列のカード）。

## 5. 基本スタイル値（角丸・シャドウ）

| トークン | 値（仮） | 用途 |
|---|---|---|
| `--radius-s` / `--radius-m` / `--radius-l` / `--radius-full` | 仮 | 小さなタグ／入力欄・ボタン／カード・ダイアログ／丸 |
| `--shadow-s` / `--shadow-m` / `--shadow-l` | 仮 | 浮いた小要素／メニュー／ダイアログ |

- 内側の角丸 = 外側の角丸 − 間の余白（4 未満にしない）。

## 6. コンポーネントスタイリング

部品の一覧と状態は [component-map.md](component-map.md)、実装は [components.css](components.css)。

| 部品 | 主な Variant | 状態（`state`） |
|---|---|---|
| ボタン | `type`: primary / secondary / text、`size`: small / medium / large | normal / hover / pressed / focused / disabled |
| 入力 | `size` | normal / focused / filled / error / disabled |
| 選択（セレクト・チェック・ラジオ） | `type` | normal / selected / focused / disabled |
| テーブル | `density` | 行：normal / hover / selected |
| カード | `type` | normal / hover / selected |
| ナビゲーション（ヘッダー・サイドメニュー・タブ） | `type` | current / notCurrent |
| ダイアログ | `type`: confirm / form | — |
| フィードバック（トースト・バナー・空状態） | `type`: success / warning / error / info | — |

## 7. Do's and Don'ts

| Do | Don't |
|---|---|
| トークンとクラスだけで画面を作る | 値を直書きする、近い値に丸める |
| 主ボタンは1画面に1つ | 主ボタンを並べる |
| 素材にない部品は「不足」と報告する | それらしい部品を作り込む |
| 状態（空・エラー・読み込み中）を用意する | 正常の状態だけを作る |
| `<導入先で追記>` | `<導入先で追記>` |

## 8. Agent Prompt Guide

AIに画面を頼むときの書き方（詳細は [../../docs/B_design-rules/process.md](../../docs/B_design-rules/process.md)）。

```text
.claude/PROTOTYPE.md と guidelines/kit/DESIGN.md に従って、次の画面を作ってください。
素材にない部品が必要なら、作る前に一覧で質問してください。

# 画面骨子：<画面名>
目的：…／主要操作：…／表示：…／状態：…／画面サイズ：…
```

## 更新履歴

| 版 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v0.1 | 2026-11-26 | テンプレートとして作成（値は仮） | — |
