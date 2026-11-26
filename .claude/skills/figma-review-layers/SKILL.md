---
name: figma-review-layers
description: "Figmaのレイヤー名をデザインシステムの命名ルール（guidelines/rules/layer-naming-rules.md）に基づいてレビューし、違反箇所と修正案をユーザーに提示するスキル。画面フレーム（画面モード）とデザインシステム公開コンポーネントの内部レイヤー（ライブラリモード）の両方を対象とし、AIが読み取れる命名に整える。ユーザーの指示があった場合のみレイヤー名を変更する。対象はFigma URLのnode-idから自動取得する。"
disable-model-invocation: true
---

# Figma レイヤー名レビュースキル

**MANDATORY**: `use_figma` を呼び出す前に必ず figma-use を読み込むこと。

**Always pass `skillNames: "figma-review-layers"` when calling `use_figma` as part of this skill.**

---

## スキルの概要

Figmaフレーム内の全レイヤー名を取得し、以下の2フェーズで動作する。

- **フェーズ1（レビュー）**: 命名ルールに照らして各レイヤーを評価し、結果を提示する
- **フェーズ2（リネーム）**: ユーザーの指示を受けて、指定レイヤーの名前を変更する

### ワークフロー上の位置づけ

**画面モード**では、次のワークフローの **3番目** に位置する。

```
1. figma-ai-review（構造レビュー）
2. レポートに基づき人間が修正
3. figma-review-layers（本スキル）… レイヤー名を記号・連番なしのlowerCamelCaseに整える
4. 画面要件書の作成
5. figma-rename-layers … 要件書のタイトル番号を「3.1.1.1_レイヤー名」形式で付与
```

**ライブラリモード**では、デザインシステム側の命名整備として単独で、または `design-system-audit` の指摘を受けて実行する。この場合 4・5 の要件書・番号付与は行わない。どちらのモードでも本スキルは単独で実行できる。

**注意**: 本スキルは figma-rename-layers の実行 **前** に使う想定。レイヤー名の先頭に `3.1.1.1_` のような番号プレフィックスが既に付いているレイヤーを検出した場合は、ワークフローの順序が想定と異なる可能性をユーザーに伝え、続行するか確認する（番号プレフィックスはR-02/R-03違反として検出されるが、これは仕様であり除外規定は設けない）。

---

## 前提条件

ユーザーから以下を受け取ること。不明な場合は実行前に確認する。

1. **FigmaファイルURL**（node-idを含むURL）
   - 例: `https://www.figma.com/design/<fileKey>/...?node-id=<nodeId>`

対象の親フレームはURLの `node-id` パラメータから自動取得する。ユーザーへの確認は不要。

---

## 対象種別（画面モード / ライブラリモード）

node-idで指定されたノードの種別から、次のどちらのモードで評価するかを判定する。判定結果は必ずレビュー結果の冒頭に明記する。

| モード | 対象の例 | F-01（画面ID） | 評価する深さ |
|---|---|---|---|
| **画面モード** | 画面フレーム、画面をまとめたセクション | **適用する** | 親フレームから主要構造（目安5階層程度）を優先し、それより深い装飾レイヤーは要求時に拡張する |
| **ライブラリモード** | デザインシステムの公開コンポーネント、コンポーネントを並べたセクション、Examples／Patternのフレーム | **適用しない**（対象トップの名前はスキップ扱い） | **全階層を評価する**（コンポーネント内部はAIがProperty・構造を読み取る対象のため深さで打ち切らない） |

判定の目安：

- 対象トップが `COMPONENT` / `COMPONENT_SET`、またはその配下に `COMPONENT` / `COMPONENT_SET` が含まれる → ライブラリモード
- 対象トップが画面IDらしい名前を持つ、または要件書の画面に対応する → 画面モード
- どちらとも判断できない場合は推測で進めず、ユーザーに確認する

ライブラリモードでは、`COMPONENT` / `COMPONENT_SET` の**名前そのもの**は本スキルの対象外とする（デザインシステム全体の命名体系は `design-system-audit` のC1が担当する）。本スキルはその**内部レイヤー名**をAIが読み取れる状態に整えることを担う。

## レビュー対象の範囲

| 対象 | 扱い |
|---|---|
| 対象トップフレーム（node-idで指定されたフレーム自身） | 画面モードでは **F-01のみで評価**（R-01〜R-07は適用しない）。ライブラリモードでは**スキップ** |
| 配下の一般レイヤー（FRAME / GROUP / TEXT / 図形 等） | R-01〜R-07で評価 |
| メインコンポーネント（`COMPONENT`）・コンポーネントセット（`COMPONENT_SET`）の**名前そのもの** | **スキップ**（Figmaのコンポーネント名をそのまま使用するため変更しない） |
| メインコンポーネントの**内部の子レイヤー** | **R-01〜R-07で評価する**（AIがコード生成する際の構造・プロパティ名の手がかりになるため）。ライブラリモードでは階層の深さで打ち切らない |
| Component propertyの対象レイヤー（Boolean・Text・Instance swapで操作されるレイヤー） | **R-01〜R-07で評価し、Property名との対応が読み取れるかも併記する**（対応が追えない場合は「要確認」として提示し、Property名の変更提案はしない） |
| Variant間で対応する同じ役割のレイヤー | **同名に揃っているかを確認する**（状態ごとに名前が変わるとAIがoverrideを追跡できないため、揺れがあれば要修正として提示する） |
| インスタンス（`INSTANCE`）とその内部 | **まるごとスキップ**（名前はメインコンポーネント由来であり、内部レイヤーはAPI上リネーム不可のため。スキップ一覧に表示する） |
| 非表示レイヤー（`visible === false`） | **評価対象に含める**（状態の出し分けに使われ実装対象になるため）。結果には「非表示」と注記する |

---

## 命名ルールの参照

**判定基準は本スキルに書かない。** 次のルール文書を読み、そこに定義された内容だけで判定する。

[guidelines/rules/layer-naming-rules.md](../../../guidelines/rules/layer-naming-rules.md)

このルールは **Claude Code / Codex / Figma Agent が共通で参照する**。スキル配下ではなく `guidelines/rules/` に置かれている。

### 実行時に必ず行うこと

1. **レビュー開始前にルール文書を読む。** 記憶で判定しない
2. ルール文書に定義された **F-01、R-01〜R-10、推奨語彙、報告の優先順位** に従う
3. ルール文書に書かれていない基準を、本スキルで補わない

### ルール文書が見つからない場合

**推測で判定を始めない。** 次を行う。

- ユーザーにルール文書の所在を確認する
- 所在が分からない場合、レビューを実施せず「命名ルールが参照できないため実施不可」と報告する

### ルールと実データが食い違った場合

ルール文書が正本である。**実装側の多数派に合わせて解釈しない。**

ルールに定義がない事象を見つけた場合は、勝手に判断せず「ルールに定義がない」として要確認に挙げ、**ルール文書への追記が必要**であることをユーザーに伝える。

### モードによる適用範囲

| モード | F-01（画面ID） | 適用範囲 |
|---|---|---|
| 画面モード | **適用する** | ルール文書の第1節「対象」に従う |
| ライブラリモード | **適用しない**（対象トップはスキップ） | 同上 |

ルール文書の第1節に「対象外」が定義されている。**Component / Component Set の名前そのもの、Instance とその内部、ガイドライン文書のページ、TEXTノードの自動命名**は評価しない。

---

## ステップ1: レイヤーを取得する

URLの `node-id` パラメータを取り出し（`<n>-<m>` → `<n>:<m>` に変換）、対象フレームと配下の全レイヤーを取得する。INSTANCE配下は辿らない。

```js
const NODE_ID = "<nodeId>"; // URLのnode-idを「-」→「:」に変換した値

const root = await figma.getNodeByIdAsync(NODE_ID);
if (!root) return { error: `node-id "${NODE_ID}" のフレームが見つかりません` };

const layers = [];
function collect(node, path) {
  const entry = {
    id: node.id,
    name: node.name,
    type: node.type,
    visible: node.visible !== false,
    path: path // 親までの階層パス（同名レイヤーの特定用）
  };
  // テキストレイヤーは本文の先頭を取得（役割推定・ダミー判定の手がかり）
  if (node.type === "TEXT") entry.characters = node.characters.slice(0, 40);
  layers.push(entry);

  // インスタンス配下は対象外（リネーム不可・名前はコンポーネント由来）
  if (node.type === "INSTANCE") return;
  if ("children" in node) {
    const childPath = path ? `${path} / ${node.name}` : node.name;
    for (const child of node.children) collect(child, childPath);
  }
}
collect(root, "");

return { rootId: root.id, rootName: root.name, rootType: root.type, layers };
```

---

## ステップ2: 命名ルールを評価する（Claudeが実行）

取得した各ノードに対して以下のロジックで評価する。`use_figma` は使わず、Claudeがコード上で処理する。

### 評価ロジック（擬似コード）

```
// 対象トップフレーム（layers[0] = root）の扱いはモードで分ける
// 形式（ルール文書 第6節）: 画面ID-画面名-画面状態-画面サイズ（画面ID・画面サイズは省略可）
evaluateTopFrame(root, mode):
  if mode === "library":
    status = "skip"   // ライブラリモードでは対象トップ名を評価しない
    return

  // セグメントを「-」で分割して評価する（画面ID内部の「_」とは役割が異なる）
  segments = root.name.split("-")

  // 画面ID: 空欄（セグメントが無い）を違反としない。記入されている場合のみ要件書との整合を確認する
  // 画面名: 空欄・判別不能なら要修正
  // 画面状態: 空欄・判別不能なら要修正。語彙の一致は見ない（自由記述・日本語可）。何らかの状態を表す記述が含まれているかのみ確認する
  // 画面サイズ: セグメントが無いことは違反としない。ある場合は `w`+数字（例: w1366）の形式かのみ確認する

  if 画面名セグメントが空、または画面状態セグメントが空（判別できない）:
    status = "⚠️ 要修正"
    note = "画面名・画面状態のいずれかが欠落、または判別できない"
  else:
    status = "✅ OK"
    if 画面IDセグメントが空:
      note = "画面IDは未記入（許容。要件書確定後に記入）"
    if 画面サイズセグメントがあり、`w`+数字の形式でない:
      status = "⚠️ 要修正"
      note = "画面サイズの表記が `w`+数字（例: w1366）の形式でない"

// 評価する深さ（画面モードのみ打ち切る）
if mode === "screen" and node.depth > 5 and nodeが装飾のみ:
  status = "範囲外"   // 「深い階層は未評価」として件数を明示し、要求があれば拡張する
// ライブラリモードは深さで打ち切らない

for each node in layers（root以外）:
  // スキップ判定
  if node.type in ["COMPONENT", "COMPONENT_SET", "INSTANCE"]:
    status = "skip"   // 内部の子レイヤーは COMPONENT/COMPONENT_SET なら評価対象、INSTANCE なら取得時点で除外済み
    continue

  violations = []
  name = node.name

  // R-10: 画像塗りを持つノードの親がFRAME/COMPONENT/COMPONENT_SET/INSTANCE以外なら違反（名前不問）
  if hasImageFill(node) and node.parent.type not in [FRAME, COMPONENT, COMPONENT_SET, INSTANCE]:
    violations.push({ rule: "R-10" })
    // 命名ルールは評価せず、R-10のみ報告して次のノードへ
    continue

  // 図形系・Imageの既定名（ルール文書 R-05「図形系の許容」の完全一致）は命名評価の対象外
  if ルール文書の図形系許容パターンに完全一致:
    status = "skip"
    continue

  // 判定基準はすべて guidelines/rules/layer-naming-rules.md に定義されている。
  // ここでは適用順序のみを示す。閾値・正規表現・語彙はルール文書の値を使う。

  // 基本形式チェック（R-01〜R-03）
  if ルール文書の基本形式にマッチしない:
    if 日本語・全角文字を含む:
      violations.push({ rule: "R-02" })
    if 半角記号を含む:
      violations.push({ rule: "R-03", priority: ルール文書のR-03優先度表で判定 })
    if violations.length === 0:   // 英数字のみだがケース違反
      violations.push({ rule: "R-01" })
    // ローマ字と判断した場合もR-01として報告し、英訳を提案する

  // R-05: デフォルト名・素材名（該当したら他ルールは併記しない）
  if ルール文書のデフォルト名パターンにマッチ or 素材名パラメータ列を含む:
    violations = [{ rule: "R-05" }]

  // R-04: 機械的な連番（数字の扱いはルール文書 第4節）
  if hasSerialNumberSuffix(name, siblings):
    violations.push({ rule: "R-04" })

  // R-06: ダミーテキスト由来（TEXTノードはcharactersも参考にする）
  if looksLikeDummyText(name, node.characters):
    violations.push({ rule: "R-06" })

  // R-07: 禁止語（ルール文書の禁止語リストを使う）
  if containsForbiddenWord(name):
    violations.push({ rule: "R-07" })

  // R-08: 綴り誤り（形式が正しくても該当する。他ルールと併記可）
  //       組織固有語・製品名・造語は対象外。判断できなければ「要確認」
  if hasMisspelling(name):
    violations.push({ rule: "R-08" })

  // ライブラリモードの追加確認（R違反として数えず「要確認」として提示する）
  if mode === "library":
    if nodeがComponent propertyの対象 and Property名との対応が読み取れない:
      notes.push("Property名との対応が追えない（Property名の変更提案はしない）")
    if Variant間で同じ役割のレイヤー名が揺れている:
      notes.push("Variant間で名前が不一致（overrideが追跡できない）")

  // 判定
  if violations.length === 0:
    status = "✅ OK"
  else:
    status = "⚠️ 要修正"
    suggestedName = proposeName(node, violations)  // Claudeが修正案を提案
```

### 修正案の提案方針

**ルール文書の第4節「特殊なケースの修正方針」と第5節「推奨語彙」に従う。** ここではルール文書に書かれていない、本スキル固有の運用のみを定める。

- 修正案が推定の場合は **`（推定）`** と明記し、ユーザーが確認できるようにする
- 名前を推定する材料は、node type・階層パス・子要素・TEXTノードの `characters` 内容
- **機械的な変換で済ませない。** 素材名・CSSユーティリティ風名は、ルール文書の第4節に従って役割名に置き換える
- 1つのレイヤーに複数の違反がある場合、修正案は**1つに統合**して出す

### 報告の順序

**ルール文書の第7節「報告の優先順位」に従う。** 件数の多さで順序を決めない。

優先度「中」の違反（`_` `-` 等）が大量にある場合は、**1件ずつ列挙せずパターンでまとめる**。

```
・`spacer_left` → `spacerLeft`（84件）
・`ruby_container` → `rubyContainer`（84件）
以上 2パターン / 対象 168件
```

---

## ステップ3: レビュー結果をユーザーに提示する

以下のフォーマットで結果を提示する。同名レイヤーを特定できるよう **親レイヤー（階層パスの末尾）** を必ず併記し、非表示レイヤーには「非表示」と注記する。

```
## レイヤー名レビュー結果

対象フレーム: [フレーム名]
モード: 画面モード / ライブラリモード（判定理由を1行で記載）
総レイヤー数: XX件（うちスキップ: XX件、レビュー対象: XX件、範囲外: XX件）

### 対象フレーム名のチェック（F-01）

| フレーム名 | 判定 | 内容 |
|---|---|---|
| `requestList-エラー` | ✅ OK | 画面IDは未記入（許容。要件書確定後に記入） |
| `requestList` | ⚠️ 要修正 | 画面状態セグメントが欠落している |

※ ライブラリモードではこの節を「対象外（ライブラリモード）」とだけ記載する

---

### ⚠️ 要修正（XX件）

| # | 現在の名前 | 親レイヤー | 違反ルール | 内容 | 修正案 |
|---|-----------|-----------|-----------|------|--------|
| 1 | `解答欄です解答欄です` | `answerArea` | R-02 | 日本語（テキスト本文由来） | `answerInput`（推定） |
| 2 | `Close_Button` | `modalHeader` | R-03 | アンダースコアを含む | `closeButton` |
| 3 | `Frame 12` | `headerArea` | R-05 | Figmaのデフォルト名 | `titleArea`（推定） |
| 4 | `contentsGroup` | `mainArea`（非表示） | R-07 | 禁止語 `group` を含む | `contentsContainer` |

---

### 🔍 要確認（XX件）※ライブラリモードのみ

| # | レイヤー名 | 親レイヤー | 内容 |
|---|----------|-----------|------|
| 1 | `label` | `buttonContent` | Property `Text` との対応が追えない |
| 2 | `iconLeading` / `leadingIcon` | `Button` の各Variant | Variant間で名前が不一致 |

---

### ✅ OK（XX件）

| # | レイヤー名 | 親レイヤー |
|---|----------|-----------|
| 1 | `closeButton` | `modalHeader` |
| 2 | `answerCard` | `mainArea` |

---

### ⭐ スキップ（XX件）

| # | レイヤー名 | 種別 |
|---|----------|------|
| 1 | `Button/Primary/Default` | メインコンポーネント |
| 2 | `Button/Primary/Default` | インスタンス（内部含む） |

---

修正案の `（推定）` は意味から自動提案したものです。確認の上、必要に応じて変更してください。

修正を実行する場合は以下のいずれかを指示してください：
- 「すべて修正案で変更して」
- 「#1, #3 を変更して」
- 「#2 の名前を closeButton に変更して」（個別指定）
```

**ユーザーの指示を待つ。指示があるまで Figma への書き込みは行わない。**

---

## ステップ4: ユーザー確認後にリネームを実行する

ユーザーから実行指示があった場合のみ、対象ノードのリネームを実行する。

指示のパターン：
- **「すべて変更」**: 要修正の全件を修正案の名前で変更する
- **「#N を変更」**: 指定番号のみ変更する
- **「#N の名前を ～ に変更」**: 指定番号を指定の名前で変更する（修正案を上書き）

**TEXTノードの注意**: テキストレイヤーをリネームすると、Figmaの「本文がそのまま名前になる」自動命名が解除され、以後本文を変更しても名前に反映されなくなる。これは意図した動作（役割ベースの固定名にする）なので問題ないが、初回実行時にユーザーへ一言伝えること。

```js
// renameMap = [{ id: "node-id", newName: "変更後の名前" }, ...]
// ステップ3の結果とユーザー指示をもとに組み立てる

const renameMap = [
  // { id: "NODE_ID", newName: "newLayerName" }
];

const renamed = [];
const failed = [];
for (const { id, newName } of renameMap) {
  try {
    const node = await figma.getNodeByIdAsync(id);
    if (!node) {
      failed.push({ id, newName, reason: "ノードが見つからない（削除された可能性）" });
      continue;
    }
    node.name = newName;
    renamed.push({ id: node.id, newName });
  } catch (e) {
    failed.push({ id, newName, reason: String(e && e.message ? e.message : e) });
  }
}

return { renamedCount: renamed.length, renamed, failedCount: failed.length, failed };
```

`failed` が1件でもあれば、その一覧（対象と理由）を必ずユーザーに報告する。

---

## ステップ5: 変更後を検証する

```js
const ids = [/* ステップ4で返した renamed の id 一覧 */];
const result = [];
for (const id of ids) {
  const node = await figma.getNodeByIdAsync(id);
  if (node) result.push({ id: node.id, name: node.name });
}
return result;
```

検証結果をもとに、変更前→変更後の一覧をユーザーに提示して完了を報告する。失敗があった場合はその件数と理由も再掲する。

---

## エラーリカバリー

- エラーが起きたら即リトライせず、エラーメッセージを読む
- スクリプトは **atomic** なので、失敗しても変更は残らない
- 詳細は figma-use を参照

---

## 実行前の確認チェックリスト

- [ ] **命名ルール `guidelines/rules/layer-naming-rules.md` を読んだか？**（記憶で判定していないか）
- [ ] ルールに定義がない事象を、勝手に判断していないか？（要確認に挙げたか）
- [ ] FigmaファイルURL（node-id付き）は受け取ったか？
- [ ] node-idから対象フレームを正しく取得できたか？
- [ ] 画面モードかライブラリモードかを判定し、判定理由を結果に明記したか？（判断できない場合はユーザーに確認したか）
- [ ] 画面モードでは対象トップフレームをF-01（画面ID-画面名-画面状態-画面サイズ）で評価し、ライブラリモードでは対象外としたか？
- [ ] F-01で画面IDの空欄を違反扱いしていないか？ 画面状態を語彙の一致ではなく記述の有無だけで判定したか？
- [ ] ライブラリモードで階層の深さによる打ち切りをしていないか？ 画面モードで打ち切った場合、未評価件数を明示したか？
- [ ] ライブラリモードでProperty対応・Variant間の名前一致を「要確認」として提示したか？（Property名の変更提案をしていないか）
- [ ] COMPONENT / COMPONENT_SET / INSTANCE をスキップし、コンポーネント内部の子レイヤーは評価したか？
- [ ] INSTANCE の内部を取得対象から除外したか？
- [ ] 番号プレフィックス（`3.1.1.1_` 等）付きのレイヤーを検出した場合、ワークフロー順序をユーザーに確認したか？
- [ ] レビュー結果に親レイヤー列・非表示注記を付けたか？
- [ ] ルールの第7節「報告の優先順位」に従って並べたか？（件数順にしていないか）
- [ ] 優先度「中」の大量違反を、パターンでまとめて報告したか？
- [ ] ステップ3のレビュー結果をユーザーに提示したか？
- [ ] 修正案に `（推定）` の明記が必要なものはついているか？
- [ ] ユーザーから実行指示を受け取ったか？
