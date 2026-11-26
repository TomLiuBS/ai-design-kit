---
name: figma-guideline-sync
description: "共通DSのFigmaデザインガイドライン（fileKey・nodeは guidelines/design-system-map.md で指定）からデザイントークン・ガイドライン内容を抽出し、ローカルのガイドラインファイル群（DESIGN.md / design-tokens.json / design-tokens.css）を更新する。使用時：「ガイドラインを更新」「Figmaのガイドラインをローカルに反映」「guideline sync」と言われた時。"
argument-hint: "[figma-url]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, mcp__figmaRemoteMcp__get_metadata, mcp__figmaRemoteMcp__get_screenshot, mcp__figmaRemoteMcp__use_figma
---

# figma-guideline-sync スキル

---

## 前提条件

- Figma Desktop アプリが起動していること
- 対象ファイルが Figma Desktop で開かれていること
- Figma Remote MCP サーバーが接続されていること
- **このスキルでは `use_figma` を使用する。呼び出し前に必ず figma-use を読み込むこと**
- **`use_figma` を呼び出す際は引数に `skillNames: "figma-guideline-sync"` を必ず含めること**

---

## スキルの概要

Figmaのデザインガイドラインファイルからデザイントークンとガイドライン内容をプログラムで抽出し、ローカルのMarkdown / JSON / CSSファイルに同期する。

### なぜローカルファイルに同期するか

Figmaは視覚的な情報源として優れているが、AIによる活用にはテキストデータとして言語化されたガイドラインが必要になる。ローカルファイルに同期することで：

- コードレビューやUI実装時の参照基盤になる
- ガイドラインの変更履歴をgitで管理できる

### 同期対象ファイル

| ファイル | 内容 | 更新方法 |
|---------|------|---------|
| `design-tokens.json` | デザイントークン（Tokens Studio形式） | Figmaの変数・スタイルから完全生成 |
| `design-tokens.css` | CSSカスタムプロパティ | トークンから完全生成 |
| `DESIGN.md` | デザインガイドライン総合ドキュメント（AIレビュー用） | スクリーンショット解釈＋トークンで再生成 |

**デフォルト出力先**: `guidelines/kit/`（リポジトリのルートからの相対パス）

---

## 対象のFigmaファイル（必須の入力）

同期元は**共通DSのデザインガイドライン**（fileKey: `<共通DSのfileKey>`）で、以下2つのLayerで構成される。**fileKey・ページ・node-idはスキルに固定せず、毎回 [design-system-map.md](../../../guidelines/design-system-map.md) から読む**（正本は所在マップ）。**このスキルが同期するのはこの2 Layerのみ**であり、サービス固有DS（Layer 3、同一ファイル内の別node-id）は対象外。

| Layer | node-id | 内容 | 取得フェーズ |
|---|---|---|---|
| Layer 1 | `<Layer 1のnodeId>` | ガイドライン解説文（基本方針・カラー・タイポ・スペーシング・状態） | Phase 3（トークン）, Phase 5（スクリーンショット） |
| Layer 2 | `<Layer 2のnodeId>` | 共通コンポーネント（Component Set本体） | Phase 4（コンポーネント構造） |

- URL（Layer 1）: `https://www.figma.com/design/<共通DSのfileKey>/<ファイル名>?node-id=<Layer 1のnodeId>`
- URL（Layer 2）: `https://www.figma.com/design/<共通DSのfileKey>/<ファイル名>?node-id=<Layer 2のnodeId>`

---

## ワークフロー

### Phase 0: 入力確認

1. **Figma URL の確認**
   - 引数に URL が指定されていればそれを使用
   - 指定がなければ [design-system-map.md](../../../guidelines/design-system-map.md) から `<共通DSのfileKey>` と Layer 1・Layer 2 の node-id を読み、その URL を使ってよいかユーザーに確認を取る
   - 所在マップに fileKey・node-id がない（テンプレートのまま）場合は、推測せずユーザーに URL を尋ねる
   - fileKey と nodeId を URL からパース（nodeId はハイフン区切りのままMCPツールへ渡す）

2. **出力先の確認**
   - `guidelines/kit/` ディレクトリが存在するかを確認（Glob または Bash で検索）
   - 存在しない場合：ユーザーに出力先の絶対パスを確認する
   - 存在する場合：そのパスを出力先として使用し、ユーザーに通知する

---

### Phase 1: figma-use スキルのロード

**必須ステップ**: figma-use を読み込んでから `use_figma` を呼び出す。

---

### Phase 2: ページ構造の把握

**Script P（ページ一覧取得）** を `use_figma` で実行し、ガイドラインファイルのページ構成を把握する。

```js
// Script P: ページ構造確認
const pages = figma.root.children.map(p => ({
  id: p.id,
  name: p.name,
  childCount: p.children.length,
  topLevelFrames: p.children.slice(0, 10).map(c => ({ id: c.id, name: c.name, type: c.type }))
}));
return pages;
```

取得したページ一覧をユーザーに表示する。**同期対象はLayer 1（node `<Layer 1のnodeId>`）とLayer 2（node `<Layer 2のnodeId>`）に限定する。全ページを同期対象にしない**（[design-system-map.md](../../../guidelines/design-system-map.md)の原則「取得範囲を絞る」に従う。サービス固有DS（Layer 3）を混入させると、共通のはずのDESIGN.mdにサービス固有コンポーネントが紛れ込む）。

---

### Phase 3: デザイントークン抽出

**Script A（変数コレクション＋変数値）** を `use_figma` で実行する。

```js
// Script A: 変数とコレクション
const collections = await figma.variables.getLocalVariableCollectionsAsync();
const allVariables = await figma.variables.getLocalVariablesAsync();

const result = { collections: [], variables: [] };

for (const col of collections) {
  result.collections.push({
    id: col.id,
    name: col.name,
    modes: col.modes.map(m => ({ id: m.modeId, name: m.name }))
  });
}

for (const v of allVariables) {
  const col = collections.find(c => c.id === v.variableCollectionId);
  if (!col) continue;

  const valuesByMode = {};
  for (const mode of col.modes) {
    const raw = v.valuesByMode[mode.modeId];
    if (raw === undefined) continue;
    if (typeof raw === 'object' && raw !== null && 'r' in raw) {
      // COLOR: RGBをHEXに変換
      const r = Math.round(raw.r * 255);
      const g = Math.round(raw.g * 255);
      const b = Math.round(raw.b * 255);
      const hex = '#' + [r, g, b].map(x => x.toString(16).padStart(2, '0')).join('');
      valuesByMode[mode.name] = hex;
    } else {
      valuesByMode[mode.name] = raw;
    }
  }

  result.variables.push({
    id: v.id,
    name: v.name,
    type: v.resolvedType,
    collectionName: col.name,
    valuesByMode
  });
}

return result;
```

**Script B（テキストスタイル・ペイントスタイル・エフェクトスタイル）** を `use_figma` で実行する。

```js
// Script B: ローカルスタイル
const textStyles = await figma.getLocalTextStylesAsync();
const paintStyles = await figma.getLocalPaintStylesAsync();
const effectStyles = await figma.getLocalEffectStylesAsync();

const texts = textStyles.map(s => ({
  name: s.name,
  fontFamily: s.fontName?.family ?? null,
  fontStyle: s.fontName?.style ?? null,
  fontSize: s.fontSize ?? null,
  lineHeight: s.lineHeight ?? null,
  letterSpacing: s.letterSpacing ?? null,
  paragraphSpacing: s.paragraphSpacing ?? null
}));

const paints = paintStyles.map(s => ({
  name: s.name,
  paints: s.paints.map(p => {
    if (p.type === 'SOLID') {
      const r = Math.round(p.color.r * 255);
      const g = Math.round(p.color.g * 255);
      const b = Math.round(p.color.b * 255);
      return { type: 'SOLID', hex: '#' + [r, g, b].map(x => x.toString(16).padStart(2, '0')).join(''), opacity: p.opacity ?? 1 };
    }
    return { type: p.type };
  })
}));

const effects = effectStyles.map(s => ({
  name: s.name,
  effects: s.effects.map(e => {
    const base = { type: e.type, radius: e.radius ?? null };
    if (e.color) {
      const r = Math.round(e.color.r * 255);
      const g = Math.round(e.color.g * 255);
      const b = Math.round(e.color.b * 255);
      base.colorHex = '#' + [r, g, b].map(x => x.toString(16).padStart(2, '0')).join('');
      base.colorAlpha = e.color.a ?? 1;
    }
    if (e.offset) base.offset = e.offset;
    return base;
  })
}));

return { textStyles: texts, paintStyles: paints, effectStyles: effects };
```

---

### Phase 4: コンポーネント構造の把握

**Script C（コンポーネント一覧）** を `use_figma` で実行する。**Layer 2ノード（node `<Layer 2のnodeId>` をコロン区切りにした値。design-system-map.mdが正本）配下のみ**を走査してCOMPONENT_SETと独立したCOMPONENTを収集する。全ページ走査は行わない（サービス固有DSのComponent Setが混入するため）。

```js
// Script C: コンポーネント一覧（Layer 2ノード配下のみ。node-idはdesign-system-map.mdを正本とする）
const LAYER2_NODE_ID = 'XXXX:XXXX'; // design-system-map.md の Layer 2 の node-id をコロン区切りに
const targetNode = await figma.getNodeByIdAsync(LAYER2_NODE_ID);
if (!targetNode) {
  throw new Error(`Layer 2ノード(${LAYER2_NODE_ID})が見つかりません。design-system-map.mdのnode-idが変わっていないか確認してください`);
}

const results = [];

const sets = targetNode.findAll(n => n.type === 'COMPONENT_SET');
for (const s of sets) {
  const variantProps = {};
  for (const child of s.children) {
    // "Key=Value, Key=Value" 形式のVariant名をパース
    const parts = child.name.split(',').map(p => p.trim());
    for (const part of parts) {
      const [k, v] = part.split('=').map(x => x?.trim());
      if (k && v) {
        if (!variantProps[k]) variantProps[k] = new Set();
        variantProps[k].add(v);
      }
    }
  }
  const props = Object.fromEntries(Object.entries(variantProps).map(([k, v]) => [k, [...v]]));
  results.push({ type: 'COMPONENT_SET', name: s.name, variantCount: s.children.length, variantProps: props });
}

const standalones = targetNode.findAll(n => n.type === 'COMPONENT' && n.parent?.type !== 'COMPONENT_SET');
for (const c of standalones) {
  results.push({ type: 'COMPONENT', name: c.name });
}

return results;
```

---

### Phase 5: ガイドラインページのスクリーンショット取得

Phase 2で把握したページのうち、視覚的ガイドライン（カラー・タイポグラフィ・コンポーネント・Do/Don'tなど）が含まれるページのスクリーンショットを `get_screenshot` で取得する。

- ページ数が多い場合は主要ページに絞る（カラー・タイポグラフィ・コンポーネント・ルールの4カテゴリを優先）
- nodeId なしで fileKey のみ渡すと現在のページが表示される。特定フレームを指定する場合は Phase 2 で取得したフレームIDを使用する
- スクリーンショットはClaude が内容を解釈し、Phase 6の DESIGN.md 生成に活用する

---

### Phase 6: ローカルファイルの更新

#### 6-1. design-tokens.json の更新

Phase 3 のデータを **Tokens Studio JSON形式** に変換して `design-tokens.json` を完全置換する。

**フォーマット規則:**

```json
{
  "コレクション名": {
    "変数グループ": {
      "変数名": {
        "value": "#RRGGBB または 数値",
        "type": "color | sizing | spacing | borderRadius | fontSizes | lineHeights | fontWeights | boxShadow"
      }
    }
  }
}
```

- カラー変数: `type: "color"`, `value: "#RRGGBB"`
- スペーシング変数: `type: "spacing"`, `value: "NNpx"` または数値
- ボーダー半径: `type: "borderRadius"`
- テキストスタイルは typography グループにまとめる
- 変数名のスラッシュ（`/`）はJSON階層として展開する（例: `brand/orange` → `{ "brand": { "orange": {...} } }`）
- 変数にモードが複数ある場合は、デフォルトモード（最初のモード）の値を使用する

既存の `design-tokens.json` を先に Read して構造・コレクション名の表記ゆれを確認してから生成する。

#### 6-2. design-tokens.css の更新

`design-tokens.json` のデータから CSS カスタムプロパティを生成し、`design-tokens.css` を完全置換する。

**テンプレート:**

```css
/* <DS名> デザイントークン */
/* このファイルは figma-guideline-sync スキルによって自動生成されます */
/* 最終更新: YYYY-MM-DD */

/* Webフォントを使う場合のみ: <DESIGN.md で決めた書体> を読み込む */
@import url('<書体の読み込みURL>');

:root {
  /* Brand Colors */
  --brand-[name]: [hex];

  /* Grayscale */
  --color-gray-[N]: [hex];

  /* Functional Colors */
  --color-[name]: [hex];

  /* Typography */
  --font-family-base: '<DESIGN.md で決めた書体>', sans-serif;
  --font-family-number: '<DESIGN.md で決めた数字用の書体（ある場合）>', sans-serif;

  /* Spacing */
  --spacing-[N]: [value]px;

  /* Border Radius */
  --radius-[name]: [value]px;
}
```

CSS変数名の命名規則:
- カラー: `--color-{name}` または `--brand-{name}`
- スペーシング: `--spacing-{value}` または `--spacing-{name}`
- ボーダー半径: `--radius-{name}`
- フォントサイズ: `--font-size-{name}`
- 影: `--shadow-{name}`

既存の `design-tokens.css` を先に Read して命名規則の表記ゆれを確認してから生成する。

#### 6-3. DESIGN.md の更新

既存の `DESIGN.md` を先に Read し、構成・セクション・表現を把握してから更新する。

**注意**: DESIGN.mdの正式な構成（§0〜§8）は`design-system-generate`スキルのモードAが定めるテンプレートが正本。以下の構成表は簡易版であり、既存ファイルの構成（既にモードAのテンプレートに従っている場合）を壊さないこと。

**ソース欄の記載形式（必須）**: `DESIGN.md`冒頭の「ソース」欄は、fileKeyだけでなく**セクションごとのnode-idを明記**する（Layer 1: `<Layer 1のnodeId>` はトークン・基本方針、Layer 2: `<Layer 2のnodeId>` はコンポーネント一覧）。node-idの正本は[design-system-map.md](../../../guidelines/design-system-map.md)。

**DESIGN.md の構成（簡易版。既存構成が優先）:**

```markdown
# <DS名> デザインシステム

> AIコーディングアシスタント向けデザインリファレンス

## 1. デザインシステム概要
- 対象サービスと、ブランドカラー切り替えの仕組み（複数サービスで共有する場合）

## 2. カラーパレット
- ブランドカラー
- グレースケール
- 機能色（エラー・強調・リンク等）

## 3. タイポグラフィ
- フォント定義
- テキストスタイル一覧（head1-4 / body1-3 / caption 等）

## 4. スペーシング
- 間隔トークン一覧（4px基準）

## 5. シャドウ・ボーダー
- エフェクトスタイル定義

## 6. コンポーネント一覧
- Phase 4で取得したコンポーネント名と Variant 構成

## 7. 利用ルール・ガイドライン
- スクリーンショットから解釈したDo/Don't・使用ルール
- ボタンラベルの表記ルール 等

## 8. AI開発者向けクイックリファレンス
- 実装例（CSS変数の使い方 等）
```

**更新ポリシー:**
- セクション 1〜6 はトークン・スタイル・コンポーネントデータから完全再生成する
- セクション 7 はスクリーンショットから解釈した内容で再生成する。解釈できない箇所は **既存の記述を保持**する（削除しない）
- セクション 8 は既存の記述を保持し、変数名等が変わった場合のみ更新する
- ファイル末尾に `<!-- 最終同期: YYYY-MM-DD figma-guideline-sync -->` を追記する

---

## 完了メッセージ

```
ガイドライン同期が完了しました

【更新ファイル】
- guidelines/kit/design-tokens.json
- guidelines/kit/design-tokens.css
- guidelines/kit/DESIGN.md

【抽出概要】
- 変数コレクション: N個
- 変数: N個（カラー: N / 数値: N）
- テキストスタイル: N個
- ペイントスタイル: N個
- エフェクトスタイル: N個
- コンポーネント: N個（COMPONENT_SET: N / 単体: N）

【確認推奨事項】
- DESIGN.md のセクション7（ガイドライン）はAI解釈を含むため目視確認を推奨
- git diff で変更内容を確認後、コミットしてください
```

---

## 注意事項

- **DESIGN.md はAI生成のため目視確認が必須**: スクリーンショットからの解釈に誤りが含まれる可能性がある
- ブランドカラー（サービスごとに切り替える場合は、各サービスの分）が正しく抽出されているか確認すること
- 変数が存在しない場合（Figmaファイルにローカル変数が未定義の場合）はペイントスタイルのデータのみで生成する
- 更新後は `git diff` で変更点を確認し、チームに共有してからコミットすること
