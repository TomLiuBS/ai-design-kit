# figma-library-structure.md — Figma ライブラリの構成案

素材の正本となる Figma ライブラリの、ページと Variables の構成案です。ファイルの所在は `../design-system-map.md` に書きます。

## 1. ファイル

| ファイル | 中身 | 公開 |
|---|---|---|
| `<サービス名> Design Kit` | Foundations・Components・Templates | ライブラリとして公開 |
| （任意）`<サービス名> Design Kit — Sandbox` | 試作・検証用 | 公開しない |

修正は **ブランチ** で行い、確認してから本体にマージして再公開します（`design-system-apply-fixes` も検証用ブランチに書き込みます）。

## 2. ページ

| ページ | 中身 |
|---|---|
| `Cover` | 版・更新日・連絡先 |
| `Foundations` | 色・文字・余白・角丸・影・アイコンの見本（Variables を表示） |
| `Components` | 基本部品（component-map.md の順）。1部品 = 1 Component Set |
| `Templates` | 画面テンプレート5種（layout-patterns.md） |
| `Deprecated` | 廃止した部品（名前に 🚫 を付ける。AIは選ばない） |
| `Changelog` | 更新履歴 |

## 3. Variables のコレクション

ルールの詳細は `../rules/variables-rules.md`。

| コレクション | 中身 | 例 | 画面で使う |
|---|---|---|---|
| `Primitive` | 原色の段階・数値の段階 | `neutral/900`、`brand/500`、`space/4` | 使わない |
| `Semantic`（モード：Light／必要なら Dark） | 役割の名前で Primitive を参照 | `color/text`、`color/primary`、`color/surface` | 使う |
| `Spacing` / `Radius` | 余白・角丸 | `space/2`、`radius/m` | 使う |

- 色は `Semantic` から使う。`Primitive` を直接当てない。
- 値が完全に一致する変数だけを当てる。近い値に丸めない。
- 変数名と CSS 変数の対応：`color/text` → `--color-text`、`space/2` → `--space-2`。

## 4. Component の作り方

ルールの詳細は `../rules/component-authoring-rules.md`・`../rules/variant-naming-rules.md`・`../rules/description-format.md`。

- 分類は Variant の軸で表し、名前に詰め込まない（`type`・`size`・`state`）。
- 状態（`state`）の値は決められた語だけ（normal / hover / pressed / focused / disabled / selected / error など）。
- Boolean は `is〜`・`has〜`・`show〜` の3種類だけ。
- Component Set に Description（`用途`・`選び分け`・`Property`・`禁止`）を書く。4行・200字以内。
- 配置した部品（インスタンス）は直接編集しない。直すのは元の部品。
