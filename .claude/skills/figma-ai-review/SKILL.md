---
name: figma-ai-review
description: "FigmaファイルがAI駆動開発に適した設計かどうかを8項目で審査し、スコアカード形式のレビューレポートを作成するスキル。コンポーネント化・命名規則・Auto Layout・スタイル/Variables・Variant・レスポンシブ・ページ構成を網羅的にチェックする。レポートの保存先はリポジトリの共通ルールに従う。"
allowed-tools: Read, Write, Glob, Bash, mcp__figmaRemoteMcp__get_metadata, mcp__figmaRemoteMcp__get_screenshot, mcp__figmaRemoteMcp__use_figma
---

# figma-ai-review スキル

---

## 前提条件

- Figma Desktop アプリが起動していること
- 対象ファイルが Figma Desktop で開かれていること
- Figma Remote MCP サーバーが接続されていること
- **このスキルでは `use_figma` を使用する。呼び出し前に必ず figma-use を読み込むこと**
- **`use_figma` を呼び出す際は引数に `skillNames: "figma-ai-review"` を必ず含めること**

---

## スキルの概要

FigmaデザインがAI駆動開発に適した品質かどうかを8項目でチェックし、スコアカード形式のレビューレポートを生成・保存する。

### 評価項目一覧

| # | 項目 | 何を確認するか |
|---|------|------------|
| 1 | コンポーネント化の徹底 | 繰り返し要素がINSTANCEとして利用されているか |
| 2 | コンポーネント命名規則の統一 | スラッシュ階層命名（例: `Button/Primary/Large`）が統一されているか |
| 3 | Auto Layout の利用 | FRAMEノードにAuto Layoutが適用されているか |
| 4 | スタイル定義（Color/Text/Effect） | 色・文字・影がスタイルとして登録・参照されているか（ローカル値直書きでないか） |
| 5 | Variables 対応 | カラー・余白・フォントサイズ等がVariablesで管理されているか |
| 6 | Variant の利用 | ボタン等のインタラクティブ要素が状態ごとにVariant管理されているか |
| 7 | レスポンシブ考慮 | 制約設定やサイジングモードが固定値（FIXED）に偏っていないか |
| 8 | ページ構成ルール | ページ名が整理され、用途ごとに分かれているか |

---

## ワークフロー

### Phase 0: 入力情報の取得

ユーザーから以下を受け取る。未提供の場合は実行前に確認する：

1. **Figma URL**
   - フレームURL（推奨）: `https://www.figma.com/design/{fileKey}/{fileName}?node-id={nodeId}`
   - セクションURL: セクションを選択してコピーしたURLも使用可。セクション内の全フレームが対象になる
   - ファイルURL: node-idなしの場合は現在表示中のページ全体を対象とする
2. **保存先プロジェクト名**（後述の「Phase 5: 保存先確認」参照）

**URL解析**:
- `fileKey`: URLパスの `/design/` 直後の文字列
- `nodeId`: `node-id=` パラメータの値。**ハイフン区切り**のままMCPツールに渡す（例: `<n>-<m>`）
- figma-use JSで使う際はコロン区切りに変換する: `<n>-<m>` → `<n>:<m>`

---

### Phase 1: figma-use スキルのロード

**必須ステップ**: figma-use を読み込んでから `use_figma` を呼び出す。

---

### Phase 2: 情報収集（並列実行）

以下を**並列**で取得する:

1. **スクリーンショット**: `mcp__figmaRemoteMcp__get_screenshot`（fileKey, nodeId）
   - 目視確認・全体構成の把握に使用する
2. **メタデータ**: `mcp__figmaRemoteMcp__get_metadata`（fileKey, nodeId）
   - XMLのノード構造を把握し、大まかなコンポーネント構成を確認する

---

### Phase 3: 詳細検査（figma-use JS実行）

3つのスクリプトを順番に実行し、チェック項目の生データを収集する。

> **スコープ設定**: nodeIdが指定されている場合はそのノード（フレーム・セクション）の配下を対象とする。指定がない場合は `figma.currentPage` を対象とする。

---

#### Script A: 構造スキャン

**対応チェック項目**: No.1（コンポーネント化）、No.2（命名規則）、No.3（Auto Layout）、No.6（Variant）、No.7（レスポンシブ）

```js
const NODE_ID = "XX:XXXX"; // URLのnode-idをハイフン→コロンに変換した値。なければ null
const scopeNode = NODE_ID
  ? await figma.getNodeByIdAsync(NODE_ID)
  : figma.currentPage;
if (!scopeNode) return { error: `Node "${NODE_ID}" が見つかりません` };

// ページ切り替えが必要な場合
let parent = scopeNode.parent;
while (parent && parent.type !== "PAGE") parent = parent.parent;
if (parent && parent.type === "PAGE") await figma.setCurrentPageAsync(parent);

const allNodes = "findAll" in scopeNode ? scopeNode.findAll(() => true) : [];

const result = {
  totalNodes: allNodes.length,
  // No.1: コンポーネント化
  instances: 0,
  frames: 0,
  groups: 0,
  // No.2: 命名規則
  componentNames: [],      // COMPONENT / COMPONENT_SET の名前一覧
  // No.3: Auto Layout
  framesWithAL: 0,
  framesWithoutAL: 0,
  // No.6: Variant
  componentSets: [],       // { name, variantCount, properties }
  standaloneComponents: 0,
  // No.7: レスポンシブ
  constraintDist: {},      // "水平/垂直" → 件数
  sizingModes: {}          // "primaryAxis/counterAxis" → 件数
};

for (const n of allNodes) {
  // ---- No.1: ノードタイプカウント ----
  if      (n.type === "INSTANCE")  result.instances++;
  else if (n.type === "FRAME")     result.frames++;
  else if (n.type === "GROUP")     result.groups++;

  // ---- No.2: コンポーネント名収集 ----
  if (n.type === "COMPONENT_SET") {
    result.componentNames.push(n.name);
    result.componentSets.push({
      name: n.name,
      variantCount: n.children ? n.children.length : 0,
      properties: Object.keys(n.variantGroupProperties || {})
    });
  }
  if (n.type === "COMPONENT") {
    result.componentNames.push(n.name);
    if (n.parent && n.parent.type !== "COMPONENT_SET") result.standaloneComponents++;
  }

  // ---- No.3: Auto Layout ----
  if (n.type === "FRAME") {
    if (n.layoutMode && n.layoutMode !== "NONE") {
      result.framesWithAL++;
      // No.7: サイジングモード
      const sm = `${n.primaryAxisSizingMode}/${n.counterAxisSizingMode}`;
      result.sizingModes[sm] = (result.sizingModes[sm] || 0) + 1;
    } else {
      result.framesWithoutAL++;
    }
  }

  // ---- No.7: 制約（Constraints）----
  if ("constraints" in n && n.constraints) {
    const key = `${n.constraints.horizontal}/${n.constraints.vertical}`;
    result.constraintDist[key] = (result.constraintDist[key] || 0) + 1;
  }
}

result.componentNames = result.componentNames.slice(0, 60);
result.componentSets  = result.componentSets.slice(0, 30);

return result;
```

---

#### Script B: スタイル・Variables検査

**対応チェック項目**: No.4（スタイル定義）、No.5（Variables）

```js
const NODE_ID = "XX:XXXX"; // URLのnode-idをハイフン→コロンに変換した値。なければ null
const scopeNode = NODE_ID
  ? await figma.getNodeByIdAsync(NODE_ID)
  : figma.currentPage;
if (!scopeNode) return { error: `Node "${NODE_ID}" が見つかりません` };

let parent = scopeNode.parent;
while (parent && parent.type !== "PAGE") parent = parent.parent;
if (parent && parent.type === "PAGE") await figma.setCurrentPageAsync(parent);

const allNodes = "findAll" in scopeNode ? scopeNode.findAll(() => true) : [];

let fillsWithStyle = 0, fillsWithoutStyle = 0;
let textWithStyle = 0, textWithoutStyle = 0;
let effectsWithStyle = 0, effectsWithoutStyle = 0;
let boundVarNodes = 0;
const localFillSamples = [];  // スタイル未使用ノードのサンプル

for (const n of allNodes) {
  // ---- No.4: 塗りスタイル ----
  if ("fillStyleId" in n) {
    if (n.fillStyleId) {
      fillsWithStyle++;
    } else if (n.fills && n.fills.some && n.fills.some(f => f.type === "SOLID" || f.type === "GRADIENT_LINEAR")) {
      fillsWithoutStyle++;
      if (localFillSamples.length < 15)
        localFillSamples.push({ id: n.id, name: n.name, type: n.type });
    }
  }

  // ---- No.4: テキストスタイル ----
  if ("textStyleId" in n) {
    if (n.textStyleId) textWithStyle++;
    else               textWithoutStyle++;
  }

  // ---- No.4: エフェクトスタイル ----
  if ("effectStyleId" in n) {
    if (n.effectStyleId) effectsWithStyle++;
    else if (n.effects && n.effects.length > 0) effectsWithoutStyle++;
  }

  // ---- No.5: Variables バインド ----
  const bv = n.boundVariables;
  if (bv && Object.keys(bv).length > 0) boundVarNodes++;
}

// ---- No.4: 定義済みスタイル数（ファイル全体） ----
const definedColorStyles  = figma.getLocalPaintStyles().length;
const definedTextStyles   = figma.getLocalTextStyles().length;
const definedEffectStyles = figma.getLocalEffectStyles().length;

// ---- No.5: Variables定義状況（ファイル全体） ----
const definedVariables = figma.variables.getLocalVariables().length;
const varCollections = figma.variables.getLocalVariableCollections().map(c => ({
  name: c.name,
  modes: c.modes.map(m => m.name),
  variableCount: c.variableIds.length
}));

return {
  fills:   { withStyle: fillsWithStyle,   withoutStyle: fillsWithoutStyle,  samples: localFillSamples },
  text:    { withStyle: textWithStyle,    withoutStyle: textWithoutStyle },
  effects: { withStyle: effectsWithStyle, withoutStyle: effectsWithoutStyle },
  definedStyles: {
    colors:  definedColorStyles,
    text:    definedTextStyles,
    effects: definedEffectStyles
  },
  variables: {
    defined: definedVariables,
    boundNodes: boundVarNodes,
    collections: varCollections
  }
};
```

---

#### Script C: ページ構成確認

**対応チェック項目**: No.8（ページ構成ルール）

```js
// ページ構成はファイル全体を対象とするため figma.root を使う
const pages = figma.root.children.map(p => ({
  name: p.name,
  frameCount: p.children ? p.children.filter(n => n.type === "FRAME").length : 0
}));
return {
  fileName: figma.root.name,
  pageCount: pages.length,
  pages
};
```

---

### Phase 4: チェック判定・スコアリング

Script A/B/C の結果をもとに、以下の基準で各項目を **✅ OK / ⚠️ 要改善 / ❌ NG** で評価する。

> **注意**: 閾値は目安であり、プロジェクトの状況・フェーズに応じて判断を加味すること。

#### No.1 コンポーネント化の徹底

| 判定 | 基準 |
|------|------|
| ✅ OK | `instances / (instances + frames + groups)` ≥ 70% |
| ⚠️ 要改善 | 40〜69% |
| ❌ NG | < 40%、またはINSTANCEがほぼ存在しない |

**何を見るか**: Script Aの `instances`・`frames`・`groups` カウントからINSTANCE比率を算出する。比率が低い場合、繰り返し要素がFRAMEやGROUPで手作りされている可能性が高い。

#### No.2 コンポーネント命名規則の統一

| 判定 | 基準 |
|------|------|
| ✅ OK | `componentNames` の80%以上が `/` 区切り階層命名（例: `Button/Primary/Large`）で、言語・ケースが統一されている |
| ⚠️ 要改善 | 50〜79%が `/` 区切り、または言語混在（日英混在等）が一部ある |
| ❌ NG | `/` 区切りが50%未満、または命名に体系がない |

**何を見るか**: Script Aの `componentNames` リストを正規表現 `/^[^\/]+\/[^\/]+/` で検査し、スラッシュ階層命名の遵守率を算出する。また、名前に日本語・英語・記号が混在していないかを確認する。

```js
// Claude側で計算する（use_figmaは不要）
const withHierarchy = componentNames.filter(n => /^[^\/]+\/[^\/]+/.test(n));
const ratio = withHierarchy.length / componentNames.length;
```

#### No.3 Auto Layout の利用

| 判定 | 基準 |
|------|------|
| ✅ OK | FRAMEノードのAuto Layout適用率 ≥ 80% |
| ⚠️ 要改善 | 50〜79% |
| ❌ NG | < 50%、またはAuto Layoutがほとんど使われていない |

**何を見るか**: Script Aの `framesWithAL / (framesWithAL + framesWithoutAL)` を算出する。

#### No.4 スタイル定義（Color / Text / Effect）

| 判定 | 基準 |
|------|------|
| ✅ OK | 塗りスタイル参照率 ≥ 80% かつ テキストスタイル参照率 ≥ 80% |
| ⚠️ 要改善 | どちらか一方が50〜79% |
| ❌ NG | 塗りまたはテキストのスタイル参照率が50%未満、または定義済みスタイルがゼロ |

**何を見るか**: Script Bの `fills` および `text` の `withStyle / (withStyle + withoutStyle)` を算出する。`definedStyles.colors` や `definedStyles.text` が0の場合はスタイル自体が未定義のため即NG。

#### No.5 Variables 対応

| 判定 | 基準 |
|------|------|
| ✅ OK | Variablesのコレクションが1つ以上定義され、かつ `boundNodes` ≥ 1（実際に使用されている） |
| ⚠️ 要改善 | コレクションは定義されているが `boundNodes` が0（定義だけで未使用） |
| ❌ NG | `variables.defined` が0（Variables自体が未定義） |

**何を見るか**: Script Bの `variables.collections` でコレクションの有無と内容を確認する。

#### No.6 Variant の利用

| 判定 | 基準 |
|------|------|
| ✅ OK | `componentSets` が3つ以上あり、各々2状態以上のVariantを持つ |
| ⚠️ 要改善 | `componentSets` が1〜2つのみ |
| ❌ NG | `componentSets` が0（Variant管理が全くされていない） |

**何を見るか**: Script Aの `componentSets` リストを確認する。ボタン・入力欄等のインタラクティブ要素の状態（通常・Hover・Disabled等）がVariantで管理されているかを見る。

#### No.7 レスポンシブ考慮

| 判定 | 基準 |
|------|------|
| ✅ OK | 縦横ともに固定（FIXED/FIXED）の制約が全体の20%未満 |
| ⚠️ 要改善 | FIXED/FIXEDが20〜50% |
| ❌ NG | FIXED/FIXEDが50%以上を占める |

**何を見るか**: Script Aの `constraintDist` で `FIXED/FIXED` の割合を確認する。`sizingModes` で `FIXED/FIXED` のサイジングモード比率も参照する。

#### No.8 ページ構成ルール

| 判定 | 基準 |
|------|------|
| ✅ OK | ページ数が2〜10で、用途がわかる命名（Design・Draft・Archive、または日本語の統一命名）になっている |
| ⚠️ 要改善 | ページ数は適切だが命名が不統一（番号だけ・意味のない名前等） |
| ❌ NG | ページが1枚のみ（全要素が混在）、またはページ名が "Page 1" のまま |

**何を見るか**: Script Cの `pages` リストを確認する。

---

### Phase 5: 保存先の確認

レポート保存前に、ユーザーに保存先を確認する：

```
レビュー対象の識別名を教えてください。最終成果物は共通ルールに従って保存します。
（例: "SCR_01_申請一覧" のような画面名、または "共通" など）
```

確認後、以下のパスに保存する：

```
共通ルールに従う最終成果物
```

- `yyyymmddhhmm` はレビュー実行時点の日時（例: `202506091430`）
- ディレクトリが存在しない場合は作成する

---

### Phase 6: レポート生成・保存

以下のフォーマットでレポートを生成し、Phase 5で確認したパスに保存する。

---

## レポートフォーマット

````markdown
# figma-ai-review レポート

| 項目 | 内容 |
|------|------|
| **対象** | [Figma URL] |
| **プロジェクト** | [プロジェクト名] |
| **レビュー日時** | YYYY-MM-DD HH:MM |
| **総合スコア** | X / 8 項目 OK |

---

## サマリー

[2〜3行の総評。特に優先して改善すべき点と、よくできている点を簡潔に記載する]

---

## チェック結果

| # | 項目 | 結果 | 詳細 |
|---|------|------|------|
| 1 | コンポーネント化の徹底 | ✅/⚠️/❌ | INSTANCEの割合: XX%（INSTANCE: N / FRAME: N / GROUP: N） |
| 2 | コンポーネント命名規則の統一 | ✅/⚠️/❌ | スラッシュ階層命名: XX% 準拠（N / N コンポーネント） |
| 3 | Auto Layout の利用 | ✅/⚠️/❌ | FRAMEへの適用率: XX%（適用: N / 未適用: N） |
| 4 | スタイル定義（Color/Text/Effect） | ✅/⚠️/❌ | 塗りスタイル参照率: XX% / テキストスタイル参照率: XX% / エフェクトスタイル参照率: XX% |
| 5 | Variables 対応 | ✅/⚠️/❌ | コレクション: N個 / 定義Variables: N個 / 使用ノード: N個 |
| 6 | Variant の利用 | ✅/⚠️/❌ | コンポーネントセット: N個（例: ボタン/3状態, 入力欄/4状態） |
| 7 | レスポンシブ考慮 | ✅/⚠️/❌ | 縦横固定（FIXED/FIXED）: XX% / 可変（HUG・FILL・SCALE）: XX% |
| 8 | ページ構成ルール | ✅/⚠️/❌ | ページ数: N / [ページ名一覧] |

---

## 改善アクション

### 優先度：高（❌ NG 項目）

[NG項目のみ記載。なければこのセクションは省略]

**[項目名]**
- 現状: [数値や検出された問題]
- 推奨: [具体的な改善方法]

### 優先度：中（⚠️ 要改善 項目）

[要改善項目のみ記載]

**[項目名]**
- 現状: [数値や検出された問題]
- 推奨: [具体的な改善方法]

---

## 詳細データ

### コンポーネント命名サンプル（No.2）

```
[componentNamesの先頭20件程度を列挙。命名規則に問題のあるものに ⚠️ を付ける]
```

### スタイル未使用ノードのサンプル（No.4）

| ノード名 | ノードタイプ | ID |
|---------|-----------|-----|
| [name] | [type] | [id] |
````

---

## 完了メッセージ

```
figma-ai-review が完了しました

【総合スコア】 X / 8 項目 OK

【保存先】
共通ルールに従う最終成果物

【優先改善項目】
❌ [NG項目名]（[理由の要約]）
⚠️ [要改善項目名]（[理由の要約]）

【次のステップ】
このレビュー後は以下の順で進めてください：
1. 本レポートの改善アクションをもとに人間がFigmaを修正
2. figma-review-layers でレイヤー名をレビュー・修正（「レイヤー名をチェックして」）
3. 画面要件書を作成
4. figma-rename-layers で要件書のタイトル番号をレイヤー名に付与（「要件書の番号をFigmaに反映して」）
```

---

## レビュー後のワークフロー

本スキルは以下のワークフローの **1番目** に位置する。完了メッセージには必ず【次のステップ】を含め、ユーザーが次に何をすべきか分かるようにする。

```
1. figma-ai-review（本スキル）… 構造レビュー ※レイヤー名の個別チェックは行わない
2. レポートに基づき人間が修正
3. figma-review-layers … レイヤー名を記号・連番なしのlowerCamelCaseに整える
4. 画面要件書の作成
5. figma-rename-layers … 要件書のタイトル番号を「3.1.1.1_レイヤー名」形式で付与
```

**役割分担**: 一般レイヤー名の命名規則チェック（lowerCamelCase・デフォルト名・ダミーテキスト等）は figma-review-layers の担当であり、本スキルでは行わない。本スキルの No.2（コンポーネント命名規則）はコンポーネント名のスラッシュ階層のみを対象とする。

---

## エラーリカバリー

- `use_figma` でエラーが発生した場合は即リトライせず、エラーメッセージを読んでからスクリプトを修正する
- `findAll(() => true)` がタイムアウトする場合は、スコープをより小さい単位に絞り込む（ファイル全体 → 特定ページ → 特定フレーム）
- `figma.variables` が未定義エラーになる場合は Variables API非対応のFigmaバージョンの可能性がある。その項目のみ「確認不可」として記載する
- 詳細は figma-use を参照
