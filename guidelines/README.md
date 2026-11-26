# guidelines/ ディレクトリ README

デザインシステム（DS）を、AIが読み取りやすい形でローカルに保持するディレクトリ。AIは Figma 上のDSを毎回直接読むのではなく、ここに同期したファイルを参照してプロトタイプの作成やDSレビューを行う。

**正本は Figma のDSである。** このディレクトリのファイルは、Figma のDSから同期・生成した写しであり、食い違いがあれば Figma 側を正とし、ここを更新する。

## 構成

```
guidelines/
├── README.md                 このファイル
├── design-system-map.md      DSの所在（fileKey・ページ・node-id）の地図（テンプレート）
├── rules/                    Figma の命名・構造・Description・Variables のルール
├── kit/                      共通DSのローカル版（判断ルール・トークン・部品CSS）
└── <service>/                サービス固有の上乗せ（任意）
```

## 同期の流れ

Figma からこのディレクトリへの同期は、3つのスキルが分担している。**この順番で実行する。**

```
figma-guideline-sync（トークン・文書の同期）
        ↓ design-tokens.css/json を読む
figma-components-css-sync（コンポーネントCSSの同期）
        ↓ components.css を書く
design-system-generate（既存CSSを読んで説明文書化）
```

各スキルの詳細は `.claude/skills/` 配下の各 `SKILL.md` を参照。

---

## ファイル一覧と役割

### design-system-map.md

**各DSの「所在」（fileKey・ページ・node-id）だけを持つ正本。** 部品名・トークン名・スコアなど内容そのものは書かない。他のファイルやスキルがどの Figma node-id を参照すべきかは、必ずこのファイルを基準にする。導入時に、テンプレートの表へ実際の値を記入する。

Figma 側は次の3層で整理する（詳細は map 本文を参照）。

| Layer | 内容 |
|---|---|
| Layer 1 | 共通ガイドライン解説文（トーン&マナー・カラー・タイポ・状態） |
| Layer 2 | 共通コンポーネント（Component Set 本体） |
| Layer 3 | サービス固有DS（任意） |

### rules/

Figma 上の命名・構造・Description 記載・Variables の適用に関するルール集。**AIやツールが独自に基準を再定義せず、必ずこのルールを参照する**という位置づけ。`design-system-audit-skill` や `figma-review-layers` 等のレビュー系スキルが判定基準として参照する。

| ファイル | 内容 | ルールID |
|---|---|---|
| `layer-naming-rules.md` | レイヤー名・対象トップフレーム名の形式 | R-01〜R-10・F-01 |
| `variant-naming-rules.md` | Component Set 名・Variant 軸名・値・Property 名の形式 | V-01〜V-09 |
| `component-authoring-rules.md` | Component を作る・更新するときのルール | CA-00〜CA-10 |
| `variables-rules.md` | 余白・角丸・色・文字への Variables / Style の適用 | VR-00〜VR-05 |
| `description-format.md` | Component の Description の書き方 | — |

- **更新**: 人が判断して更新する（DSレビューでの発見事項を反映する場合も、レビュー担当が確認した上で更新する）。手順は `design-rules-editor` スキルに従う

### kit/

共通DS（Layer 1・Layer 2）のローカル版。

| ファイル | 内容 | 生成・更新 |
|---|---|---|
| `DESIGN.md` | 共通DSの判断ルールと使い方（AIコーディングアシスタント向け）。冒頭の「ソース」欄に、セクションごとにどの Layer・node-id に基づくかを書く | `design-system-generate`／`figma-guideline-sync` |
| `design-tokens.json` | Figma の Variables・Style（Layer 1）を Tokens Studio 形式の JSON にしたもの。他ツールとの連携用 | `figma-guideline-sync` |
| `design-tokens.css` | `design-tokens.json` と同じ内容を CSS カスタムプロパティ（`--xxx`）にしたもの。プロトタイプの HTML から `<link>` で参照する | `figma-guideline-sync` |
| `components.css` | 共通コンポーネント（Layer 2）の CSS 実装 | `figma-components-css-sync` |
| `component-map.md` | 部品 ⇔ CSSクラス ⇔ Figma の場所 ⇔ 標準の動き ⇔ 確認日の対応表。**未定義の部品は自作せず、先にDSへ追加する** | — |
| `layout-patterns.md` | 画面レイアウトの型 | — |
| `figma-library-structure.md` | Figma ライブラリのページ・セクション構成 | — |
| `components-showcase.html` | `components.css` の部品を一覧で確認するページ | — |

### &lt;service&gt;/（任意）

サービス固有の上乗せが要る場合だけ作る（Layer 3）。

- `<service>/design-system.md`：サービス固有のDS仕様。共通トークン・共通コンポーネントは `kit/DESIGN.md` を参照する前提で、重複を持たない（`design-system-generate`）
- `<service>/components.css`：サービス固有のコンポーネント CSS。`kit/` の CSS と併用する（`figma-components-css-sync`。対象 node-id は Layer 3。design-system-map.md 参照）

---

## 参照の順序

1. **Figma のDSが正本。** 何を作る・直すにも、まず **design-system-map.md** で Figma 上の所在を確認する
2. 判断ルールと使い方は **kit/DESIGN.md**（サービス固有がある場合は `<service>/design-system.md` も）
3. 使う部品と CSS クラスは **kit/component-map.md** で引く
4. 実装するときは **kit/design-tokens.css → kit/components.css**（＋ `<service>/components.css`）
5. Figma 側の命名・構造を直すなら **rules/** を確認する
