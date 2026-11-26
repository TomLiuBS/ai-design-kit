---
name: design-system-generate
description: >
  共通DSと、サービス固有の上乗せのデザインシステムドキュメントを生成・更新するスキル。
  以下の2モードで動作する：

  【モード A: 共通DSの DESIGN.md】
  「共通のデザインシステムを作成/更新して」「DESIGN.mdを更新して」と言われたとき。
  Figma の共通デザインガイドラインノードから design-tokens.css・components.css を参照し、
  `guidelines/kit/DESIGN.md` を生成または更新する。

  【モード B: サービス固有 design-system.md（任意）】
  「<サービス名>のデザインシステムを作成/更新して」と言われたとき。
  Figma のサービス固有デザインシステムノードと components.css を参照し、
  guidelines/kit/DESIGN.md と照合した上でサービス固有の `guidelines/<service>/design-system.md` を生成または更新する。

  Figma URL・CSS ファイル・サービス名を渡されたときも自動でどちらのモードか判断して起動する。
---

# design-system-generate スキル

## モード判定

まずユーザーの依頼を以下のどちらかに分類する：

| モード | キーワード例 | 出力ファイル |
|--------|------------|------------|
| **A: 共通DS** | 「共通」「DESIGN.md」| `guidelines/kit/DESIGN.md` |
| **B: サービス固有（任意）** | 「<サービス名>」「design-system.md」| `guidelines/<service>/design-system.md` |

不明な場合は「共通DSのDESIGN.mdですか？それともサービス固有のdesign-system.mdですか？」と確認する。

---

## モード A: 共通DSの DESIGN.md の生成・更新

### 対象ファイル

```
guidelines/kit/DESIGN.md
```

参照する CSS:
- `guidelines/kit/design-tokens.css` — カラー・タイポ・スペーシング等のトークン（Figma Layer 1: node `<Layer 1のnodeId>`）
- `guidelines/kit/components.css` — 共通コンポーネント（ボタン・フォーム・モーダル等）（Figma Layer 2: node `<Layer 2のnodeId>`）

node-idの正本は[design-system-map.md](../../../guidelines/design-system-map.md)。Layer 1とLayer 2は別ページなので、Figmaメタデータを取得する際は**両方のnode-idを個別に**指定すること（片方だけでは§2〜5とその他のトークン系セクションしか裏取りできない、または§6のコンポーネント系セクションしか裏取りできない）。

### 入力確認

| 項目 | 例 |
|------|-----|
| Figma URL（Layer 1: トークン・基本方針） | `https://www.figma.com/design/<共通DSのfileKey>/...?node-id=<Layer 1のnodeId>` |
| Figma URL（Layer 2: 共通コンポーネント） | `https://www.figma.com/design/<共通DSのfileKey>/...?node-id=<Layer 2のnodeId>` |
| バージョン（更新の場合）| 現在のバージョンに +0.1 |

### 処理フロー（モード A）

1. 既存の `DESIGN.md` があれば読み込んで現在のバージョン・内容を把握する
2. `design-tokens.css` を読み込んでトークン定義を一覧化する
3. `components.css` を読み込んで共通コンポーネントのクラスと使い方を把握する
4. Figmaメタデータを取得し、CSSと乖離がないか確認する（セクション名→カテゴリ対応）。**取得先はLayer 1（node `<Layer 1のnodeId>`）とLayer 2（node `<Layer 2のnodeId>`）の2箇所**であり、対象外（サービス固有DSのLayer 3）は取得しない
5. **モード A の出力フォーマット**に従って `DESIGN.md` を生成・上書き保存する（冒頭のソース欄にはLayer 1/2のnode-idを両方明記する）

### モード A の出力フォーマット

既存の `guidelines/kit/DESIGN.md` があれば、その構成を踏襲する（新規作成時は次の構成で作る）：

```
# <DS名> DESIGN.md

（更新日・ソース情報）

## 0. このファイルの使い方
## 1. Visual Theme & Atmosphere
## 2. カラーパレット
## 3. タイポグラフィ
## 4. スペーシング
## 5. 基本スタイル値（角丸・シャドウ）
## 6. コンポーネントスタイリング
   6.1 ボタン / 6.2 コントロール / 6.3 入力フォーム / 6.4 ポップアップ
   6.5 タグ/バッジ / 6.6 テーブル/リスト / 6.7 カード / 6.8 グローバルヘッダー
   6.9 ナビゲーション / 6.10 プログレスバー / 6.11 アラート / 6.12 アコーディオン
   6.13 空状態
## 7. Do's and Don'ts
## 8. Agent Prompt Guide
```

完全な実例: 既存の `guidelines/kit/DESIGN.md`（あれば）

---

## モード B: サービス固有 design-system.md の生成・更新（任意）

共通DSに上乗せが要るサービスだけが持つ。

### 対象ファイル

```
guidelines/<service>/design-system.md
```

### 入力確認

| 項目 | 例 |
|------|-----|
| Figma URL | `https://www.figma.com/design/<fileKey>/...?node-id=<nodeId>` |
| サービス名 | `<service>`（英小文字。例：`portal` / `admin-console`） |
| CSSプレフィックス | `<prefix>-`（例：`pt-` / `ac-`） |
| components.css パス | `guidelines/<service>/components.css` |
| バージョン | `v1.0.0`（新規）/ `v1.1.0`（更新）|

### 処理フロー（モード B）

**Step 1: components.css を読み込む**

- クラス名リスト（`.{prefix}-*` のルートクラス）を抽出する
- `:root {}` 内のサービス固有変数（`--{prefix}-*`）を一覧化する
- CSS変数を使わずにハードコードされた色値（`#XXXXXX`）を抽出する

**Step 2: Figma メタデータを取得する**

`mcp__figmaRemoteMcp__get_metadata` を使用する。

- URL から fileKey と nodeId をパースする（`node-id=XXXX-XXXX` → `XXXX:XXXX`）
- 結果が大きくファイルに書き出された場合は PowerShell で処理する：

```powershell
$content = Get-Content '<path>' -Raw -Encoding UTF8
$json = $content | ConvertFrom-Json
$text = $json[0].text
$m = [regex]::Matches($text, '<section[^>]*id="([^"]+)"[^>]*name="([^"]+)"')
$m | ForEach-Object { "$($_.Groups[1].Value) | $($_.Groups[2].Value)" }
```

**Step 3: CSS と Figma を照合する**

各 Figma セクション・コンポーネントに対して CSS クラスの有無を判定する：
- **defined**: components.css にクラスが存在する
- **missing**: Figma にあるが CSS に未実装

**Step 4: DESIGN.md と照合してトークン重複を除外する**

`guidelines/kit/DESIGN.md` を参照し、以下はサービスの design-system.md に**記載しない**：

| 除外するもの | 理由 |
|------------|------|
| ブランドカラー全色（`--brand-*`） | DESIGN.md §2 に定義済み |
| グレースケール（`--gray-*`） | DESIGN.md §2 に定義済み |
| 機能色（`--color-*`） | DESIGN.md §2 に定義済み |
| タイポグラフィ（フォント・サイズ・ウェイト・行間） | DESIGN.md §3 に定義済み |
| スペーシング（`--space-*`） | DESIGN.md §4 に定義済み |
| 角丸・シャドウ（`--radius-*`, `--shadow-*`） | DESIGN.md §5 に定義済み |

**design-system.md に記載する（サービス固有のみ）：**
- `--color-primary` / `--color-primary-hover` の上書き値
- サービス固有の CSS 変数（`--{prefix}-*`）
- CSS変数未定義のハードコード値（DESIGN.md トークンに含まれないもの）

完全な実例: 既存の `guidelines/<service>/design-system.md`（あれば）

---

## 共通: 品質チェックリスト

生成後に必ず確認する：

**モード A（DESIGN.md）**
- [ ] 冒頭のソース欄にLayer 1・Layer 2の両方のnode-id（design-system-map.md の値）が明記されているか
- [ ] 全セクション（§0〜§8）が揃っているか
- [ ] design-tokens.css の全変数がカラーパレット・タイポグラフィ等のテーブルに反映されているか
- [ ] HTMLスニペットが実際の CSS クラスと一致しているか
- [ ] バージョン・更新日が正確に記載されているか

**モード B（design-system.md）**
- [ ] バージョン・日付・更新履歴が正確か（既存行を消さずに追記したか）
- [ ] DESIGN.md の参照リンクが正しい相対パスか（`../kit/DESIGN.md`）
- [ ] `--color-primary` の上書き値が正しい HEX 値か
- [ ] サービス固有 CSS 変数がすべて記載されているか（`:root {}` を確認）
- [ ] DESIGN.md の共通トークンが重複して記載されていないか
- [ ] 出力先に `design-system.md` として保存したか
