# golden-sample.md — 模範画面

HTML構造・参照方法の「型」を揃えるための模範例。新しい画面を作るときは、まずこの型に沿っているか確認する。

**模範例**: `generated/prototypes/<service>/<プロト名>/<バージョンのフォルダ名>/index.html`（導入するチームが、下の「揃えるべきポイント」をすべて満たすプロトタイプを1本選び、ここにパスを書く。まだ無いときは、最初に作ったプロトタイプを人間が確認してから登録する）

模範例に選ぶプロトタイプは、次を満たしていること。

- `<head>` でDSのCSS（トークン・コンポーネント）を `guidelines/` から直接参照している（1）
- フォントとアイコンの読み込みが DESIGN.md の指定どおり（2）
- 部品のクラス名が components.css のまま、画面固有のクラスはBEM風（3）
- 値の直書きがない（4）
- 状態の切り替え（空・エラー・送信中など）がCSSクラスの付け外しで実装されている
- [review-checklist.md](review-checklist.md) の全項目に合格している

---

## 揃えるべきポイント

### 1. `<head>`でのDS参照

```html
<link rel="stylesheet" href="../../../../../guidelines/kit/design-tokens.css">
<link rel="stylesheet" href="../../../../../guidelines/kit/components.css">
<!-- サービス固有の components.css（guidelines/<service>/）がある場合は追加 -->
<link rel="stylesheet" href="prototype.css">
```

- `guidelines/`からの相対パスで直接参照する（内容をコピーしない。トークン更新時に自動で反映されるようにする）。相対パスはバージョンのフォルダから `../../../../../guidelines/...`（[CLAUDE.md](../../../CLAUDE.md)「プロトタイプの命名」）
- 画面固有のレイアウトのみ`prototype.css`に分離する

### 2. フォント・アイコン

```html
<!-- 書体は guidelines/kit/DESIGN.md で決めたもの（<DESIGN.md で決めた書体>）を、DESIGN.md に書かれた方法で読み込む -->
<link href="https://fonts.googleapis.com/css2?family=<DESIGN.md で決めた書体>&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
```

アイコンは`<span class="material-icons">icon_name</span>`で統一する。

### 3. クラス命名（Figma再取り込みを想定）

- コンポーネント単位のクラス名は`guidelines/kit/components.css`（サービス固有なら`guidelines/<service>/components.css`）で定義されている名前をそのまま使う（独自の別名を付けない）
- 画面固有のレイアウト用クラスは`ブロック名__要素名`のBEM風命名にする（例: `page-header__left`, `menu-popup__item`）
- 意味のある単位（ヘッダー、カード、リスト項目など）ごとに`<div>`を分け、Figmaのフレーム／グループ構造に対応させやすくする

### 4. 値の書き方

- 色・余白・角丸・フォントサイズは必ずCSS変数（`var(--color-gray-80)`など）を使う。生値の直書きは禁止
- インラインで値を書く場合も、変数参照のみ許可する（`style="font-size:20px"`のような生値は禁止）

---

## 新しいゴールデンサンプルの追加

より良い模範例が生まれた場合、人間承認のうえこのファイルの参照先を更新する（非定型業務）。
