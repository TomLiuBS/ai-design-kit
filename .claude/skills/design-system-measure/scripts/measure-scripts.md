# 実測スクリプト（走査範囲固定）

**このファイルが実測スクリプトの正本。** `design-system-measure` スキルが使う。`design-system-audit-skill` の `scripts/measure-scripts.md` は、ここを指す案内だけを置いている（スクリプトを二重管理しない）。

A1・C4・D1・E6・A4・B5・E1・E2、およびF1（Description記載率）・Variant／Property／Component Set名の違反候補率を再現可能に集計するための `use_figma` 実行スクリプト（Script A〜E）。**同じ対象を測れば同じ数字が出る**ように、走査範囲を固定してある（[ai-ready-criteria.md](../../design-system-audit-skill/references/ai-ready-criteria.md) の実測手順に対応）。

**スクリプトは、実行者が書き換えない。** 数え方を変えたいときは、このファイルを更新する（更新履歴に残す）。実行者ごとにスクリプトが違うと、結果がぶれる。

## ルールと照合する定数（実行前に必ず確認）

スクリプトには、ルールの値の一覧を写した定数がある。**ルールが変わっても定数が古いままだと、測定値がルールとずれる。** 測定の前に、次の表の定数と `guidelines/rules/` の該当箇所を見比べる。

- 1つでも食い違えば、**測定せずに停止し**、食い違った定数とルールの値をユーザーに伝える。
- 手元でスクリプトを書き換えて測定しない。このファイルを直して更新履歴に1行足し（＝版を上げ）、コミットしてから測る。

| 定数（スクリプト） | ルール（正本） | 照合する中身 | 最後に照合した日 |
|---|---|---|---|
| `SIZE_OK`（Script D） | variant-naming-rules V-01・V-05-1 | `size` の値の一覧 | 2026-11-24 |
| `STATE_OK`（Script D） | variant-naming-rules V-05-2 | `state` の値の2つの一覧（選択・操作系＋入力欄系） | 2026-11-24 |
| `BANNED_VALUE`（Script D） | variant-naming-rules V-05-2 | すべての軸で使わない値（`default` 系、`on`／`off`） | 2026-11-24 |
| `STATE_SYN`・`VER_SYN`（Script D） | variant-naming-rules V-04-1・V-04-3 | `state`・`ver` の同義語 | 2026-11-24 |
| `ABOLISHED`（Script B） | variables-rules | 廃止コレクションの名前 | 2026-11-24 |

## 前提

- **`use_figma` を呼ぶ前に必ず figma-use を読み込む。**
- `use_figma` の引数に `skillNames: "design-system-audit"` を含める。
- `NODE_ID` は所在マップ（[design-system-map.md](../../../../guidelines/design-system-map.md)）の node-id を**コロン区切り**にした値（例: `XXXX-XXXX` → `XXXX:XXXX`）。
- **生データを返さない。** スクリプト内で件数・頻度・キャップ済みサンプル（20〜30件）に集計してから `return` する（下記スクリプトの `violationSamples.length < 30` 等が実装例）。ノード配列や全文プロパティをそのまま返すとトークン上限超過を招く。
- **起点直下の子が多い場合は一括走査しない。** まず件数のみを数える軽量走査（`children` の数と直下のCOMPONENT_SET数だけを集計）でComponent Setが集中する領域を特定し、その領域単位で個別に測定する。一括で全階層を走査すると通信断・タイムアウトが起きやすく、失敗時の再走査でコストが倍加する。

## 走査範囲（固定）

| 項目 | 規定 |
|---|---|
| 起点 | 対象セクションのノード（`NODE_ID`） |
| 深さ | 制限なし（全階層） |
| COMPONENT / COMPONENT_SET 内部 | **走査する** |
| INSTANCE 内部 | **走査しない**（サブツリーごとスキップ） |
| 非表示レイヤー | **走査する** |

判定はスクリプトの生データをもとに [guidelines/rules/](../../../../guidelines/rules/) のルールで行う。**スクリプトは違反候補を機械的に拾うだけで、最終判定はしない。**

- **診断（任意）**: 各ノードが COMPONENT / COMPONENT_SET の内部か外部かを併せて数えておく。外部側の FRAME/INSTANCE が支配的なら、起点にDS本体以外（画面レイアウト）が混じっている疑い＝Scopeを見直す。（例: DS本体セクションでは内部が95%以上を占める）

---

## Script A: 構造・命名・Auto Layout

**対応**: A1（Component化率）／ C4（レイヤー名の違反候補）／ D1（Auto Layout率）／ 命名の生データ（C1）

```js
const NODE_ID = "XXXX:XXXX"; // 所在マップのnode-idをコロン区切りに
const scope = await figma.getNodeByIdAsync(NODE_ID);
if (!scope) return { error: `Node "${NODE_ID}" が見つかりません` };

// ページ切り替え
let p = scope.parent;
while (p && p.type !== "PAGE") p = p.parent;
if (p && p.type === "PAGE") await figma.setCurrentPageAsync(p);

// INSTANCE 内部をスキップして走査
const nodes = [];
(function walk(n) {
  nodes.push(n);
  if (n.type === "INSTANCE") return;           // 内部を走査しない
  if ("children" in n) for (const c of n.children) walk(c);
})(scope);

const DEFAULT_RE = /^(Frame|Group|Section|Slice|Component|Instance|Text|グループ|フレーム|セクション|テキスト)( \d+)?$/;
// 図形系・Imageの既定名は許容（layer-naming-rules R-05「図形系の許容」）。完全一致のみ除外
const SHAPE_OK_RE = /^(Rectangle|Line|Arrow|Ellipse|Polygon|Star|Vector|Union|Subtract|Intersect|Exclude|Image|長方形|楕円形|多角形|星|スター|直線|線|矢印|パス|ベクター|前面オブジェクトで型抜き|背面オブジェクトで型抜き|画像)( \d+)?$/;
const FRAME_PARENT = ["FRAME", "COMPONENT", "COMPONENT_SET", "INSTANCE"];
const hasImageFill = (n) => Array.isArray(n.fills) && n.fills.some(f => f.type === "IMAGE");
const MATERIAL_RE = /_FILL|_wght|_GRAD|_opsz/;
const CAMEL_RE = /^[a-z][a-zA-Z0-9]*$/;

const r = {
  totalScanned: nodes.length,
  // A1
  instances: 0, frames: 0, groups: 0,
  components: 0, componentSets: 0,
  // D1
  framesWithAL: 0, framesWithoutAL: 0,
  // C1（Component名の生データ）
  componentSetNames: [],
  variantSets: [],           // { name, variantCount, properties }
  // C4（レイヤー名の違反候補と除外の内訳）
  layerEval: 0,              // C4評価対象レイヤー数（分母）
  c4Violations: 0,
  c4Breakdown: { defaultName: 0, materialName: 0, symbolOrCaseOrJa: 0, imageOutsideFrame: 0 },
  c4Excluded: { instanceInternal: "walkでスキップ済", instanceNode: 0, textAutoNamed: 0, componentName: 0, shapeDefaultName: 0 },
  violationSamples: []       // 先頭30件
};

for (const n of nodes) {
  if (n === scope) continue;
  // ---- A1 ----
  if (n.type === "INSTANCE") r.instances++;
  else if (n.type === "FRAME") r.frames++;
  else if (n.type === "GROUP") r.groups++;
  else if (n.type === "COMPONENT") r.components++;
  else if (n.type === "COMPONENT_SET") r.componentSets++;

  // ---- D1 ----
  if (n.type === "FRAME") {
    if (n.layoutMode && n.layoutMode !== "NONE") r.framesWithAL++;
    else r.framesWithoutAL++;
  }

  // ---- C1: Component Set 名 ----
  if (n.type === "COMPONENT_SET") {
    r.componentSetNames.push(n.name);
    r.variantSets.push({
      name: n.name,
      variantCount: n.children ? n.children.length : 0,
      properties: Object.keys(n.variantGroupProperties || {})
    });
  }

  // ---- C4: レイヤー名の違反候補 ----
  // 除外: INSTANCEノード名（メイン由来・対象外）、COMPONENT/COMPONENT_SET名（C1で評価）、TEXTの自動命名
  if (n.type === "INSTANCE") { r.c4Excluded.instanceNode++; continue; }
  if (n.type === "COMPONENT" || n.type === "COMPONENT_SET") { r.c4Excluded.componentName++; continue; }
  if (n.type === "TEXT" && n.name === n.characters) { r.c4Excluded.textAutoNamed++; continue; }

  r.layerEval++;
  const name = n.name;
  let hit = false;
  // R-10: フレーム外の単独Image（名前不問）
  if (hasImageFill(n) && !(n.parent && FRAME_PARENT.includes(n.parent.type))) {
    r.c4Breakdown.imageOutsideFrame++; hit = true;
  }
  // 図形系・Imageの既定名は評価対象外（R-10に該当しない場合）
  else if (SHAPE_OK_RE.test(name)) { r.c4Excluded.shapeDefaultName++; r.layerEval--; continue; }
  else if (DEFAULT_RE.test(name))  { r.c4Breakdown.defaultName++; hit = true; }
  else if (MATERIAL_RE.test(name)) { r.c4Breakdown.materialName++; hit = true; }
  else if (!CAMEL_RE.test(name))   { r.c4Breakdown.symbolOrCaseOrJa++; hit = true; }
  if (hit) {
    r.c4Violations++;
    if (r.violationSamples.length < 30) r.violationSamples.push({ id: n.id, name, type: n.type });
  }
}

r.componentSetNames = r.componentSetNames.slice(0, 60);
r.variantSets = r.variantSets.slice(0, 40);
return r;
```

**判定への渡し方**

- A1 = `instances / (instances + frames + groups)`。
- C4 = `c4Violations / layerEval`。内訳（defaultName／materialName／symbolOrCaseOrJa／imageOutsideFrame）を報告し、**綴り誤り（R-08）・連番（R-04）・禁止語（R-07）・ローマ字はスクリプトでは拾えない**ため、`violationSamples` と名前一覧を目視で補う。最終判定は layer-naming-rules による。
- D1 = `framesWithAL / (framesWithAL + framesWithoutAL)`。
- `c4Excluded` を Scope に記録する（除外の種別別件数）。

---

## Script B: Variables / Style 適用率

**対応**: E6（適用率）／ E2 の生データ／ [variables-rules.md](../../../../guidelines/rules/variables-rules.md) VR-02 の違反数

従来の集計（`fills`・`text`）は過去値との比較用にそのまま残し、VR-02 の条件での集計を `vr02` に出す。`vr02` は VR-00 に従い、Component の中（COMPONENT とその子孫、Component Set 内の Variant）だけを数える。Component の外の説明用フレーム・Section、INSTANCE は数えない。

```js
const NODE_ID = "XXXX:XXXX";
const scope = await figma.getNodeByIdAsync(NODE_ID);
if (!scope) return { error: `Node "${NODE_ID}" が見つかりません` };

let p = scope;
while (p && p.type !== "PAGE") p = p.parent;
if (p && p.type === "PAGE") await figma.setCurrentPageAsync(p);

// 走査（INSTANCE内部は除外）。inComp = Component の中か（VR-00）
const nodes = [];
(function walk(n, parentIn) {
  const inComp = parentIn || n.type === "COMPONENT";
  nodes.push({ n, inComp });
  if (n.type === "INSTANCE") return;
  if ("children" in n) for (const c of n.children) walk(c, inComp || n.type === "COMPONENT_SET");
})(scope, false);

// ---- 従来の集計（塗り・テキスト。過去値との比較用に残す） ----
let fillWith = 0, fillWithout = 0, textWith = 0, textWithout = 0, boundVarNodes = 0;
const rawSamples = [];
for (const { n } of nodes) {
  const bv = n.boundVariables;
  if (bv && Object.keys(bv).length > 0) boundVarNodes++;
  if ("fillStyleId" in n) {
    const bound = (bv && bv.fills) ? true : false;
    if (n.fillStyleId || bound) fillWith++;
    else if (n.fills && n.fills.some && n.fills.some(f => f.type === "SOLID" || f.type === "GRADIENT_LINEAR")) {
      fillWithout++;
      if (rawSamples.length < 15) rawSamples.push({ id: n.id, name: n.name, type: n.type });
    }
  }
  if ("textStyleId" in n) {
    if (n.textStyleId) textWith++;
    else textWithout++;
  }
}

// ---- VR-02（variables-rules.md）の集計 ----
const cols = await figma.variables.getLocalVariableCollectionsAsync();
const vars = await figma.variables.getLocalVariablesAsync();
const byId = {}; for (const v of vars) byId[v.id] = v;
const colName = {}; for (const c of cols) colName[c.id] = c.name;
const firstVal = v => v.valuesByMode[Object.keys(v.valuesByMode)[0]];
const inCol = (v, name) => colName[v.variableCollectionId] === name;

const spacingVals = new Set(vars.filter(v => inCol(v, "Size") && v.name.startsWith("Spacing/")).map(firstVal));
const negativeVals = new Set(vars.filter(v => inCol(v, "Negative") && v.name.startsWith("Padding/-")).map(firstVal));

function resolve(x) { let g = 0; while (x && x.type === "VARIABLE_ALIAS" && g < 10) { const t = byId[x.id]; if (!t) return null; x = firstVal(t); g++; } return x; }
const colorKey = (c, a) => [c.r, c.g, c.b].map(x => Math.round(x * 255).toString(16).padStart(2, "0")).join("") + ((a !== undefined && a < 1) ? "@" + a.toFixed(2) : "");

// Alias を「全Modeで同じ色」と「Modeで色が変わる」に分ける
const aliasCol = cols.find(c => c.name === "Alias");
const aliasInvariant = {}, aliasModeDependent = {}, brandColors = new Set();
for (const v of vars) {
  if (v.resolvedType !== "COLOR") continue;
  if (aliasCol && v.variableCollectionId === aliasCol.id) {
    const keys = new Set(aliasCol.modes.map(m => { const r = resolve(v.valuesByMode[m.modeId]); return r ? colorKey(r, r.a) : null; }));
    const r = resolve(v.valuesByMode[aliasCol.defaultModeId]); if (!r) continue;
    const k = colorKey(r, r.a);
    const target = keys.size === 1 ? aliasInvariant : aliasModeDependent;
    (target[k] = target[k] || []).push(v.name);
  } else if (inCol(v, "Brand color")) {
    const r = firstVal(v); if (r && r.r !== undefined) brandColors.add(colorKey(r, r.a));
  }
}
const ABOLISHED = ["コレクション1", "Local Styles"];
const VECTOR_TYPES = ["VECTOR", "BOOLEAN_OPERATION", "POLYGON", "STAR", "LINE"];

const blank = () => ({ applied: 0, violation: 0 });
const padding = { ...blank(), zero: 0, noVariable: {} };
const gap = { ...blank(), zero: 0, auto: 0, noVariable: {} };
const color = { ...blank(), vectorExcluded: 0, modeDependentOnly: 0, brandOnly: 0, noVariable: 0, multipleCandidates: 0, brandDirectWithAlias: 0, abolishedCollection: 0 };
const text = { ...blank(), mixedStyle: 0 };
const vrSamples = [];
const sample = (n, kind, value) => { if (vrSamples.length < 15) vrSamples.push({ id: n.id, name: n.name, kind, value }); };
const bump = (o, v) => { o[v] = (o[v] || 0) + 1; };

for (const { n, inComp } of nodes) {
  if (!inComp || n.type === "INSTANCE") continue;   // VR-00
  const bv = n.boundVariables || {};

  // 余白（辺ごと）・Gap
  if (n.layoutMode && n.layoutMode !== "NONE") {
    for (const k of ["paddingLeft", "paddingRight", "paddingTop", "paddingBottom"]) {
      const val = n[k];
      if (bv[k]) padding.applied++;
      else if (val === 0) padding.zero++;
      else if (spacingVals.has(val)) { padding.violation++; sample(n, k, val); }
      else bump(padding.noVariable, val);
    }
    const gaps = [["itemSpacing", n.itemSpacing, n.primaryAxisAlignItems === "SPACE_BETWEEN"]];
    if (n.layoutWrap === "WRAP") gaps.push(["counterAxisSpacing", n.counterAxisSpacing, n.counterAxisAlignContent === "SPACE_BETWEEN"]);
    for (const [k, val, isAuto] of gaps) {
      if (bv[k]) gap.applied++;
      else if (isAuto) gap.auto++;                       // 均等配置（間隔が自動）
      else if (val === 0 || val == null) gap.zero++;
      else if (val < 0 ? negativeVals.has(val) : spacingVals.has(val)) { gap.violation++; sample(n, k, val); }
      else bump(gap.noVariable, val);
    }
  }

  // 塗り色（SOLID）
  if ("fills" in n && Array.isArray(n.fills)) {
    const styled = typeof n.fillStyleId === "string" && n.fillStyleId !== "";
    for (const f of n.fills) {
      if (f.type !== "SOLID" || f.visible === false) continue;
      if (VECTOR_TYPES.includes(n.type)) { color.vectorExcluded++; continue; }
      const a = f.boundVariables && f.boundVariables.color;
      if (styled || a) {
        color.applied++;
        if (a && byId[a.id]) {
          const bvVar = byId[a.id];
          if (ABOLISHED.includes(colName[bvVar.variableCollectionId])) color.abolishedCollection++;
          // VR-01: Brand color に直接付いているが、同じ色の全Mode共通 Alias がある
          if (inCol(bvVar, "Brand color")) { const r = resolve(firstVal(bvVar)); if (r && aliasInvariant[colorKey(r, r.a)]) color.brandDirectWithAlias++; }
        }
        continue;
      }
      const k = colorKey(f.color, f.opacity);
      const inv = aliasInvariant[k];
      if (inv && inv.length === 1) { color.violation++; sample(n, "fill", "#" + k + " → " + inv[0]); }
      else if (inv) color.multipleCandidates++;             // 要判断
      else if (aliasModeDependent[k]) color.modeDependentOnly++;
      else if (brandColors.has(k)) color.brandOnly++;
      else color.noVariable++;
    }
  }

  // 文字
  if (n.type === "TEXT") {
    if (n.textStyleId === figma.mixed) text.mixedStyle++;
    else if (n.textStyleId || bv.fontSize) text.applied++;
    else { text.violation++; sample(n, "text", n.fontSize === figma.mixed ? "mixed" : n.fontSize); }
  }
}

const top = o => Object.entries(o).sort((x, y) => y[1] - x[1]).slice(0, 20);
padding.noVariable = top(padding.noVariable);
gap.noVariable = top(gap.noVariable);

return {
  fills:  { withToken: fillWith, rawValue: fillWithout, samples: rawSamples },
  text:   { withStyle: textWith, rawValue: textWithout },
  boundVarNodes,
  vr02: { padding, gap, color, text, samples: vrSamples },
  collections: cols.map(c => ({ name: c.name, modes: c.modes.map(m => m.name), variableCount: c.variableIds.length }))
};
```

**判定への渡し方**

- **E6（VR-02）** = 余白・Gap・色・文字ごとに `applied / (applied + violation)`。分母と分子、`samples` を併記する。
- `vr02` の次の件数は**違反に数えない**（VR-02「違反にしないもの」）。件数だけを記録する: `zero`、`noVariable`（値ごとの件数）、`auto`、`vectorExcluded`、`modeDependentOnly`、`brandOnly`、`mixedStyle`。`multipleCandidates` は「要判断」として件数を記録する。
- `color.brandDirectWithAlias`（VR-01の違反候補）、`color.abolishedCollection`（廃止コレクションの使用）は補助情報として記録する。
- **従来値** = 塗り `withToken / (withToken + rawValue)`、テキスト `withStyle / (withStyle + rawValue)`。過去の測定値と比べるときだけ使う（`vr02` とは範囲・条件が違うので比べない）。
- コレクション名（`Size` `Negative` `Alias` `Brand color` 等）が変わった場合は、スクリプトを更新するまで `vr02` を「測定できなかった項目」とする。
- E1（Token階層の参照方向）は `collections` と Alias を別途確認する（Figma内から数え切れないため本スキルが判断）。

---

## Script C: Description記載率

**対応**: F1（Component description）の記載率／ description-format.md の必須ラベル・分量の機械チェック

**対象と分母**: Component Set と、Set に属さない単体 Component（Description は親に1つ書く＝description-format.md §3）。Set の子Variantは数えない。名前が `🚫` で始まるものは評価対象外（V-08）として件数のみ記録する。

```js
const NODE_ID = "XXXX:XXXX"; // 所在マップのnode-idをコロン区切りに
const scope = await figma.getNodeByIdAsync(NODE_ID);
if (!scope) return { error: `Node "${NODE_ID}" が見つかりません` };

// ページ切り替え
let p = scope.parent;
while (p && p.type !== "PAGE") p = p.parent;
if (p && p.type === "PAGE") await figma.setCurrentPageAsync(p);

// 対象は「Component Set」と「Setに属さない単体Component」（Descriptionは親に1つ書く：description-format §3）
// INSTANCE 内部は走査しない。Component Set の子Variantは数えない
const targets = [];
(function walk(n, inSet) {
  if (n.type === "INSTANCE") return;
  if (n.type === "COMPONENT_SET") { targets.push(n); return; }
  if (n.type === "COMPONENT" && !inSet) targets.push(n);
  if ("children" in n) for (const c of n.children) walk(c, inSet);
})(scope, false);

const REQUIRED = ["用途"];
const r = {
  targets: targets.length,
  componentSets: targets.filter(t => t.type === "COMPONENT_SET").length,
  standaloneComponents: targets.filter(t => t.type === "COMPONENT").length,
  deprecatedExcluded: 0,          // 名前が🚫で始まるもの（V-08：評価対象外）
  evaluated: 0,                   // 分母
  filled: 0,                      // 分子（Descriptionが空でない）
  empty: 0,
  requiredLabels: { "用途": 0 },
  allRequiredLabels: 0,           // 必須ラベル（用途）がある
  overLimit: 0,                   // 4行超 または 200字超
  emptySamples: []                // 先頭30件
};

for (const t of targets) {
  if (t.name.startsWith("🚫")) { r.deprecatedExcluded++; continue; }
  r.evaluated++;
  const d = (t.description || "").trim();
  if (!d) {
    r.empty++;
    if (r.emptySamples.length < 30) r.emptySamples.push({ id: t.id, name: t.name, type: t.type });
    continue;
  }
  r.filled++;
  const lines = d.split(/\r?\n/).filter(l => l.trim()).length;
  if (lines > 4 || d.length > 200) r.overLimit++;
  let all = true;
  for (const label of REQUIRED) {
    if (new RegExp("(^|\\n)\\s*" + label + "\\s*[:：]").test(d)) r.requiredLabels[label]++;
    else all = false;
  }
  if (all) r.allRequiredLabels++;
}
return r;
```

**判定への渡し方**

- **Description記載率** = `filled / evaluated`。分母・分子と、`deprecatedExcluded`（除外件数）を併記する。
- 参考値: 必須ラベル（用途）がある件数 `allRequiredLabels`、4行・200字を超えた件数 `overLimit`。旧形式（使う／使わない／関連を含む）の Description は4行を超えることがあるが、違反とは扱わない。**ラベルの有無と分量しか見ない。内容が業務的に正しいか、「選び分け」「Property」「禁止」が要る部品かの判断はしない**（F1・F2の評価はClaudeが description-format.md に照らして行う）。
- `emptySamples` は先頭30件のみ。全件の一覧が要る場合は件数を絞って再走査する。

---

## Script D: Variant・Property・Component Set名の違反候補率

**対応**: A5（Property名）／ B1・B2（Variant軸・値）／ C1（Component Set名）／ V-04-3 の `ver` 軸（A3・CA-01 の補助）

**スクリプトは違反候補を機械的に拾うだけで、最終判定はしない。** 業務固有の日本語軸・値（V-04-2）は違反にせず `review`（要確認）に分ける。判定は variant-naming-rules.md による。

**対象**: Component Set と、Set に属さない単体 Component（評価単位）。名前が `🚫` で始まるSet、および値が `🚫` で始まるVariant値は評価対象外（V-08）として件数のみ記録する。値が `🚫` で始まるもののうち `ver` 軸以外の軸にあるものは、`deprecatedValuesNonVer` として別に件数を記録する（参考値。V-08の付け方に反する候補。違反率には含めない）。Property キーの内部ID（`#`以降）は命名の対象外。

```js
const NODE_ID = "XXXX:XXXX"; // 所在マップのnode-idをコロン区切りに
const scope = await figma.getNodeByIdAsync(NODE_ID);
if (!scope) return { error: `Node "${NODE_ID}" が見つかりません` };

// ページ切り替え
let p = scope.parent;
while (p && p.type !== "PAGE") p = p.parent;
if (p && p.type === "PAGE") await figma.setCurrentPageAsync(p);

// 対象は「Component Set」と「Setに属さない単体Component」。INSTANCE 内部は走査しない
const targets = [];
(function walk(n, inSet) {
  if (n.type === "INSTANCE") return;
  if (n.type === "COMPONENT_SET") { targets.push(n); return; }
  if (n.type === "COMPONENT" && !inSet) targets.push(n);
  if ("children" in n) for (const c of n.children) walk(c, inSet);
})(scope, false);

const CAMEL = /^[a-z][a-zA-Z0-9]*$/;
const JA = /[぀-ヿ㐀-鿿]/;
const GENERIC = /^(Property|プロパティ|propaty|Component|Frame|Union|バリアント|variant)\s*\d*$/i;
const STATE_SYN = /^(status|states?)$/i;               // V-04-1（"state"以外）
const VER_SYN = /^(version|バージョン|期)$/i;           // V-04-3（"ver"以外）
const VER_IN_TEXT = /(^|[^a-z])(ver|v)\s?\d|\d+(\.\d+)?\s?期/i; // V-05-3 / V-06
const SIZE_OK = new Set(["xxlarge", "xlarge", "large", "medium", "small", "xsmall", "xxsmall"]); // V-01・V-05-1
const STATE_OK = new Set([                                                                  // V-05-2
  "normal", "hover", "disabled", "focused", "pressed", "selected", "unselected", "current", "notCurrent", "partiallySelected", "drag", // 選択・操作系
  "empty", "filled", "inputting", "error"                                                   // 入力欄系（focused・disabled は上と共通）
]);
const BANNED_VALUE = /^(default|デフォルト|defualt|on|off)$/i;                              // V-05-2（すべての軸）
const bump = (o, k) => { o[k] = (o[k] || 0) + 1; };

const r = {
  units: 0, unitsWithCandidate: 0, deprecatedExcluded: 0, // 評価単位＝Component Set + 単体Component
  axes:     { eval: 0, flagged: 0, breakdown: {}, review: {} },   // Variant軸名（V-04）
  values:   { eval: 0, flagged: 0, deprecatedValuesExcluded: 0, deprecatedValuesNonVer: 0, breakdown: {}, review: {} }, // Variant値（V-05）
  valueSets:{ eval: 0, flagged: 0, breakdown: {} },                // 軸単位の値の揃い（言語・大小文字の混在。V-04-2 / V-05-4）
  variants: { eval: 0, flagged: 0 },                               // 違反候補の値を1つ以上含むバリアントの数（B2。🚫の値を含むバリアントは除外）
  props:    { eval: 0, flagged: 0, breakdown: {}, review: {} },   // Variant以外のProperty名（V-07）
  setNames: { eval: 0, flagged: 0, breakdown: {}, review: {}, duplicateNames: 0 }, // Component Set名（V-06）
  ver:      { setsWithVerAxis: 0, groups: 0, groupsNotExactlyOne: 0, samples: [] }, // V-04-3 / CA-01
  samples: []   // 先頭30件
};
const nameCount = new Map();

function sample(t, kind, item, flags) {
  if (r.samples.length < 30) r.samples.push({ id: t.id, set: t.name, kind, item, flags });
}
// 名前のチェック。{f: 違反候補, rv: 要確認}
function nameCheck(name, { checkProp }) {
  const f = [], rv = [];
  if (GENERIC.test(name)) f.push("genericName");                       // V-04-4
  else if (checkProp === "axis" && name !== "state" && STATE_SYN.test(name)) f.push("stateSynonym");
  else if (checkProp === "axis" && name !== "ver" && VER_SYN.test(name)) f.push("verSynonym");
  else if (JA.test(name)) { rv.push("japaneseName"); if (/[A-Za-z]/.test(name)) f.push("mixedLanguageInName"); } // 業務固有なら許容（V-04-2）
  else if (!CAMEL.test(name)) f.push("notLowerCamel");                 // 大文字始まり・記号・スペース・数字始まり
  return { f, rv };
}
function valueCheck(axis, v) {
  const f = [], rv = [];
  if (axis === "ver") { if (!/^\d+(\.\d+)*$/.test(v)) f.push("verFormat"); return { f, rv }; }
  if (axis === "breakpoint") { if (!/^\d+$/.test(v)) f.push("breakpointFormat"); return { f, rv }; }
  if (BANNED_VALUE.test(v)) f.push("bannedValue");                     // V-05-2（default・on/off）
  else if (GENERIC.test(v)) f.push("defaultOrGeneric");                // V-04-4
  else if (VER_IN_TEXT.test(v)) f.push("versionInValue");              // V-05-3
  else if (/^\d+$/.test(v)) f.push("numericOnly");                     // V-05-2 / V-09
  else if (v.includes("仮")) rv.push("provisionalMarker");             // V-08：要確認
  else if (JA.test(v) && /[A-Za-z]/.test(v)) f.push("mixedLanguageInValue");
  else if (JA.test(v)) rv.push("japaneseValue");                       // 業務固有なら許容（V-04-2）
  else if (!CAMEL.test(v)) f.push("notLowerCamel");
  if (axis === "size" && !SIZE_OK.has(v)) f.push("sizeNotInSpec");     // V-01 / V-05-1
  if (axis === "state" && !JA.test(v) && !STATE_OK.has(v) && !BANNED_VALUE.test(v)) f.push("stateNotInList"); // V-05-2（日本語の業務固有の状態は要確認のまま）
  return { f, rv };
}

for (const t of targets) {
  if (t.name.startsWith("🚫")) { r.deprecatedExcluded++; continue; }
  r.units++;
  const unitFlags = [];
  const defs = t.componentPropertyDefinitions || {};
  const flaggedPairs = new Set();                                      // 違反候補の「軸=値」（B2のバリアント単位の集計に使う）

  // Component Set 名（V-06）
  if (t.type === "COMPONENT_SET") {
    r.setNames.eval++;
    nameCount.set(t.name, (nameCount.get(t.name) || 0) + 1);
    const f = [], rv = [];
    if (VER_IN_TEXT.test(t.name)) f.push("versionInName");
    for (const seg of t.name.split("/")) {
      if (JA.test(seg)) { rv.push("japaneseName"); if (/[A-Za-z]/.test(seg)) f.push("mixedLanguageInName"); }
      else if (!CAMEL.test(seg)) f.push("notLowerCamel");
      if (/\d/.test(seg)) rv.push("hasDigit");                         // V-09：例外があるため要確認
    }
    rv.forEach(k => bump(r.setNames.review, k));
    if (f.length) { r.setNames.flagged++; f.forEach(k => bump(r.setNames.breakdown, k)); unitFlags.push("setName"); sample(t, "setName", t.name, f); }
  }

  for (const [key, def] of Object.entries(defs)) {
    const name = key.replace(/#.*$/, "");                              // 内部ID（#以降）は命名の対象外
    if (def.type === "VARIANT") {
      // 軸名
      r.axes.eval++;
      const a = nameCheck(name, { checkProp: "axis" });
      a.rv.forEach(k => bump(r.axes.review, k));
      if (a.f.length) { r.axes.flagged++; a.f.forEach(k => bump(r.axes.breakdown, k)); unitFlags.push("axis"); sample(t, "axis", name, a.f); }
      // 値
      const live = [];
      for (const v of (def.variantOptions || [])) {
        if (v.startsWith("🚫")) { r.values.deprecatedValuesExcluded++; if (name !== "ver") r.values.deprecatedValuesNonVer++; continue; } // V-08：違反としない
        live.push(v);
        r.values.eval++;
        const c = valueCheck(name, v);
        c.rv.forEach(k => bump(r.values.review, k));
        if (c.f.length) { r.values.flagged++; c.f.forEach(k => bump(r.values.breakdown, k)); unitFlags.push("value"); flaggedPairs.add(`${name}=${v}`); sample(t, "value", `${name}=${v}`, c.f); }
      }
      // 同一軸内の言語混在・大小文字混在（V-04-2 / V-05-4）。軸単位で数える
      if (live.length) {
        r.valueSets.eval++;
        const jaOnly = live.some(v => JA.test(v) && !/[A-Za-z]/.test(v)), enOnly = live.some(v => !JA.test(v));
        const hasUp = live.some(v => /^[A-Z]/.test(v)), hasLow = live.some(v => /^[a-z]/.test(v));
        const sf = [];
        if (jaOnly && enOnly) sf.push("mixedLanguageInAxis");
        if (hasUp && hasLow) sf.push("caseMixedInAxis");
        if (sf.length) { r.valueSets.flagged++; sf.forEach(k => bump(r.valueSets.breakdown, k)); unitFlags.push("valueSet"); sample(t, "valueSet", name, sf); }
      }
    } else {
      // Variant以外のProperty名（V-07）
      r.props.eval++;
      const a = nameCheck(name, { checkProp: "prop" });
      const f = a.f.slice();
      if (def.type === "BOOLEAN" && !a.f.length && !a.rv.length && !/^(show|has|is)[A-Z0-9]/.test(name)) f.push("booleanPrefix"); // V-07-2
      a.rv.forEach(k => bump(r.props.review, k));
      if (f.length) { r.props.flagged++; f.forEach(k => bump(r.props.breakdown, k)); unitFlags.push("prop"); sample(t, "prop", name, f); }
    }
  }

  // バリアント単位の集計（B2）：違反候補の値を1つ以上含むバリアントを数える
  if (t.type === "COMPONENT_SET") {
    for (const c of (t.children || [])) {
      const pairs = c.name.split(",").map(s => s.trim()).filter(s => s.includes("=")).map(s => {
        const i = s.indexOf("="); return `${s.slice(0, i).trim()}=${s.slice(i + 1).trim()}`;
      });
      if (pairs.some(p => p.split("=")[1].startsWith("🚫"))) continue;   // V-08：🚫の値を含むバリアントは対象外
      r.variants.eval++;
      if (pairs.some(p => flaggedPairs.has(p))) r.variants.flagged++;
    }
  }

  // ver軸：他の軸の値の組ごとに、🚫でない値がちょうど1つか（V-04-3 / CA-01）
  if (t.type === "COMPONENT_SET" && Object.keys(defs).some(k => k === "ver" && defs[k].type === "VARIANT")) {
    r.ver.setsWithVerAxis++;
    const groups = new Map();
    for (const c of (t.children || [])) {
      const kv = {};
      for (const part of c.name.split(",")) {
        const i = part.indexOf("=");
        if (i > 0) kv[part.slice(0, i).trim()] = part.slice(i + 1).trim();
      }
      if (!("ver" in kv)) continue;
      const key = Object.keys(kv).filter(k => k !== "ver").sort().map(k => `${k}=${kv[k]}`).join(",");
      const g = groups.get(key) || { live: 0 };
      if (!kv.ver.startsWith("🚫")) g.live++;
      groups.set(key, g);
    }
    for (const [key, g] of groups) {
      r.ver.groups++;
      if (g.live !== 1) {
        r.ver.groupsNotExactlyOne++;
        if (r.ver.samples.length < 10) r.ver.samples.push({ id: t.id, set: t.name, combo: key, liveCount: g.live });
        unitFlags.push("ver");
      }
    }
  }
  if (unitFlags.length) r.unitsWithCandidate++;
}
r.setNames.duplicateNames = [...nameCount.values()].filter(n => n > 1).length;
return r;
```

**判定への渡し方**

- **Variant違反候補率（Component単位）** = `unitsWithCandidate / units`。Tier1→2の「Variant違反候補率」はこの値を使う。分母・分子と `deprecatedExcluded` を併記する。
- **B2（値の一貫性）はバリアント単位で数える**: `variants.flagged / variants.eval`。値の種類の数（`values.flagged / values.eval`）は内訳として併記するが、B2の点には使わない。
- 内訳は項目別に併記する: 軸名 `axes.flagged / axes.eval`、値 `values.flagged / values.eval`、軸単位の値の揃い `valueSets.flagged / valueSets.eval`、Property名 `props.flagged / props.eval`、Component Set名 `setNames.flagged / setNames.eval`。それぞれ `breakdown`（違反種別）を報告する。
- `review`（`japaneseName`／`japaneseValue`／`provisionalMarker`／`hasDigit`）は**違反に数えない**。業務固有語・例外の可能性があるため、`samples` と名前一覧を見て variant-naming-rules.md（V-04-2・V-08・V-09）で人が判定する。
- `ver.groupsNotExactlyOne` は、`ver` 軸を持つSetで「他の軸の値の組ごとに🚫でない値がちょうど1つ」を満たさない組の数。正本の一意性（A3・CA-01）の補助指標として使う（率ではなく件数で報告する）。
- `setNames.duplicateNames` は、同名のComponent Setが複数あるときの名前の種類数（V-06「名前の一意性」）。ファイル単位の判定なので、起点を分けて走査した場合は結果を突き合わせる。
- **スクリプトでは拾えないもの**: 綴り誤り（R-08）、機能名と種別名の語順、軸で表すべき差分が値に埋め込まれていないか（CA-02）、ローマ字、同一軸名が複数のComponentで違う意味に使われているか。これらは `samples`・名前一覧を目視で補う。
- 値に `仮` を含むものは、`🚫` と別のマーカーの可能性があるため `review` に分ける（要確認。V-08）。

---

## Script E: Property の公開・組合せの欠け・変数の参照先

**対応**: A4（Component properties）／ B5（組合せの完全性）／ E1（Token階層）／ E2（Semantic token利用）

**対象**: Script D と同じ（Component Set と、Set に属さない単体 Component。名前が `🚫` で始まるものは除外）。INSTANCE の内部は走査しない（INSTANCE ノード自体は数える）。

- **A4**: 各対象の先頭のバリアント（単体Componentはそれ自体）の**直下の子**のうち、TEXT と INSTANCE を数え、Component Property（Text・Instance swap・Boolean）が付いていないものを数える。
- **B5**: Variant 軸の値の掛け合わせの数と、実際にあるバリアントの組合せの数の差（欠け）を数える。`🚫` で始まる値は掛け合わせからも実在からも除く。欠けた組合せは先頭20件をサンプルにする。
- **E1・E2**: 対象の中（COMPONENT・COMPONENT_SET の内部。INSTANCE の内部は除く）で参照している変数を、重複を除いて数える。各変数の既定モードの値が別の変数への参照（Alias）か、値を直接持つか（Primitive）を分ける。Alias は、参照先が別のコレクションにあるか（階層が分かれているか）も数える。ライブラリの変数で中身を読めないものは `unresolved` に分け、違反に数えない。

```js
const NODE_ID = "XXXX:XXXX"; // 所在マップのnode-idをコロン区切りに
const scope = await figma.getNodeByIdAsync(NODE_ID);
if (!scope) return { error: `Node "${NODE_ID}" が見つかりません` };

// ページ切り替え
let p = scope.parent;
while (p && p.type !== "PAGE") p = p.parent;
if (p && p.type === "PAGE") await figma.setCurrentPageAsync(p);

// 対象は「Component Set」と「Setに属さない単体Component」。INSTANCE 内部は走査しない
const targets = [];
if (scope.type === "COMPONENT_SET" || scope.type === "COMPONENT") targets.push(scope);
else (function walk(n) {
  if (n.type === "INSTANCE") return;
  if (n.type === "COMPONENT_SET" || n.type === "COMPONENT") { targets.push(n); return; }
  if ("children" in n) for (const c of n.children) walk(c);
})(scope);

const r = {
  units: 0, deprecatedExcluded: 0,
  a4: { eval: 0, noProperty: 0, byType: { TEXT: 0, INSTANCE: 0 }, samples: [] },
  b5: { setsEval: 0, combos: 0, existing: 0, missing: 0, samples: [] },
  vars: { referenced: 0, alias: 0, primitive: 0, unresolved: 0, aliasCrossCollection: 0, aliasSameCollection: 0, aliasBroken: 0, primitiveSamples: [] }
};
const varIds = new Set();

function collectVarIds(n) {
  const bv = n.boundVariables || {};
  for (const v of Object.values(bv)) {
    for (const a of (Array.isArray(v) ? v : [v])) if (a && a.type === "VARIABLE_ALIAS") varIds.add(a.id);
  }
  for (const key of ["fills", "strokes"]) {
    const paints = n[key];
    if (Array.isArray(paints)) for (const pt of paints) {
      const a = pt && pt.boundVariables && pt.boundVariables.color;
      if (a && a.type === "VARIABLE_ALIAS") varIds.add(a.id);
    }
  }
}
function walkInside(n) {
  collectVarIds(n);
  if (n.type === "INSTANCE") return;                                   // INSTANCE の内部は走査しない
  if ("children" in n) for (const c of n.children) walkInside(c);
}
const parse = name => {
  const kv = {};
  for (const part of name.split(",")) { const i = part.indexOf("="); if (i > 0) kv[part.slice(0, i).trim()] = part.slice(i + 1).trim(); }
  return kv;
};

for (const t of targets) {
  if (t.name.startsWith("🚫")) { r.deprecatedExcluded++; continue; }
  r.units++;

  // A4：先頭のバリアント（単体Componentはそれ自体）の直下の TEXT・INSTANCE
  const first = t.type === "COMPONENT_SET" ? (t.children || [])[0] : t;
  if (first && "children" in first) for (const c of first.children) {
    if (c.type !== "TEXT" && c.type !== "INSTANCE") continue;
    r.a4.eval++;
    const refs = c.componentPropertyReferences || {};
    if (!refs.characters && !refs.mainComponent && !refs.visible) {
      r.a4.noProperty++; r.a4.byType[c.type]++;
      if (r.a4.samples.length < 20) r.a4.samples.push({ set: t.name, layer: c.name, type: c.type });
    }
  }

  // B5：軸の値の掛け合わせと実在の差
  if (t.type === "COMPONENT_SET") {
    const axes = Object.entries(t.componentPropertyDefinitions || {})
      .filter(([, d]) => d.type === "VARIANT")
      .map(([k, d]) => [k.replace(/#.*$/, ""), (d.variantOptions || []).filter(v => !v.startsWith("🚫"))]);
    if (axes.length) {
      r.b5.setsEval++;
      const existing = new Set();
      for (const c of (t.children || [])) {
        const kv = parse(c.name);
        if (Object.values(kv).some(v => v.startsWith("🚫"))) continue;
        existing.add(axes.map(([k]) => `${k}=${kv[k]}`).join(", "));
      }
      let combos = [[]];
      for (const [k, vals] of axes) combos = combos.flatMap(c => vals.map(v => [...c, `${k}=${v}`]));
      r.b5.combos += combos.length;
      r.b5.existing += existing.size;
      for (const c of combos) {
        const key = c.join(", ");
        if (!existing.has(key)) { r.b5.missing++; if (r.b5.samples.length < 20) r.b5.samples.push(`${t.name}: ${key}`); }
      }
    }
  }

  walkInside(t);
}

// E1・E2：参照している変数の種類
for (const id of varIds) {
  r.vars.referenced++;
  const v = await figma.variables.getVariableByIdAsync(id);
  if (!v) { r.vars.unresolved++; continue; }
  const col = await figma.variables.getVariableCollectionByIdAsync(v.variableCollectionId);
  const val = col ? v.valuesByMode[col.defaultModeId] : undefined;
  if (val === undefined) { r.vars.unresolved++; continue; }
  if (val && typeof val === "object" && val.type === "VARIABLE_ALIAS") {
    r.vars.alias++;
    const target = await figma.variables.getVariableByIdAsync(val.id);
    if (!target) r.vars.aliasBroken++;
    else if (target.variableCollectionId === v.variableCollectionId) r.vars.aliasSameCollection++;
    else r.vars.aliasCrossCollection++;
  } else {
    r.vars.primitive++;
    if (r.vars.primitiveSamples.length < 20) r.vars.primitiveSamples.push({ name: v.name, collection: col ? col.name : null });
  }
}
return r;
```

**判定への渡し方**

- **A4**: `a4.noProperty / a4.eval`（Property が付いていない TEXT・INSTANCE の割合）。
- **B5**: `b5.missing / b5.combos`（欠けた組合せの割合）。Description に「作らない組合せ」として `軸=値` の形でそのまま書かれた組合せは、欠けから引く（引いた件数と組合せを記録する）。
- **E2**: `vars.primitive /（vars.referenced − vars.unresolved）`（値を直接持つ変数を直接参照している割合）。
- **E1**: `（vars.aliasSameCollection + vars.aliasBroken）/ vars.alias`（階層が分かれていない、または参照先が切れている Alias の割合）。`vars.alias` が0（Alias をまったく参照していない）なら、階層がないので E1 は0点とする。
- `vars.unresolved` は件数を記録し、違反に数えない。`unresolved` が `referenced` の半分を超えるときは、E1・E2 を「未検証（環境が原因）」とする（ライブラリの変数が読めていないため）。

---

## エラー時

- `use_figma` がエラーなら即リトライせず、メッセージを読んでスクリプトを直す（figma-use のError recovery参照）。
- `walk` がタイムアウトする場合は `NODE_ID` をより小さいセクションに絞る。**絞った場合は走査範囲が変わるため、Scopeに記録し、前回と得点を比較しない。**
- `figma.variables` が未定義なら Variables API 非対応版の可能性。E6・E1 を「未検証」とする。

---

## 更新履歴

スクリプトを変えたら、ここに1行追加する。測定報告の「測定スクリプトの版」には、この表の最新の日付を書く。

| 日付 | 内容 |
|---|---|
| 2026-11-26 | 汎用キットとして初版作成（v1.0） |
