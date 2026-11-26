---
name: figma-components-css-sync
description: "Figmaの共通コンポーネント（Layer 2）またはサービス固有コンポーネント（Layer 3。任意）から、実際のCSSクラス実装（components.css）を生成・更新するスキル。使用時：「components.cssを更新して」「Figmaのコンポーネントをcomponents.cssに反映して」と言われた時。design-tokens.css/jsonの生成はfigma-guideline-syncの担当、既存components.cssを読んで説明文書化するのはdesign-system-generateの担当であり、本スキルはその中間（componentsの実装そのものを書く）を担う。"
---

# figma-components-css-sync スキル

Figma上のコンポーネント（Component Set）の実装を、既存の[design-tokens.css](../../../guidelines/kit/design-tokens.css)のCSS変数を使って`components.css`に書き出す。

## 3スキルの関係（必ず理解した上で使う）

```
figma-guideline-sync（トークン・文書の同期）
        ↓ design-tokens.css/jsonを読む
figma-components-css-sync（本スキル：コンポーネントCSSの同期）
        ↓ components.cssを書く
design-system-generate（既存CSSを読んで説明文書化）
```

- **design-tokens.css/jsonが先**。本スキルはこれを前提に、トークン参照（`var(--xxx)`）でCSSを書く。トークンが古い場合は先に`figma-guideline-sync`を実行する
- 本スキルの出力（`components.css`）は、その後`design-system-generate`が読み込んで説明文書に反映する

---

## 前提条件

- Figma Desktopアプリが起動し、対象ファイルが開かれていること
- **必須**: `use_figma`呼び出し前にfigma-useを読み込むこと
- `use_figma`呼び出し時は`skillNames: "figma-components-css-sync"`を含めること
- 対象node-idは[design-system-map.md](../../../guidelines/design-system-map.md)を正本とする（全ページ走査は行わない）

---

## STEP 0: 対象確認

| 項目 | 共通DS（Layer 2）の場合 | サービス固有（Layer 3。任意）の場合 |
|---|---|---|
| node-id | Layer 2: `<Layer 2のnodeId>`（design-system-map.md参照） | Layer 3: サービスごとのnode-id（design-system-map.md参照） |
| 出力先 | `guidelines/kit/components.css` | `guidelines/<service>/components.css` |
| 参照トークン | `kit/design-tokens.css`のみ | `kit/design-tokens.css` + サービス固有トークン（あれば） |

サービス固有の層は、共通DSに上乗せが要るサービスだけが持つ（任意）。

不明な場合はユーザーに確認する。

---

## STEP 1: 対象ノードを直接取得

`figma.getNodeByIdAsync(nodeId)`で対象node-idのノードを直接取得する。`figma.root.children`での全ページ走査は行わない（サービス固有DSの混入を防ぐため。[figma-guideline-sync](../figma-guideline-sync/SKILL.md)と同じ方針）。

---

## STEP 2: 既存components.cssのクラス命名規則を把握

既存の`components.css`を先にReadし、クラス命名パターン（例: `.ol-btn-primary`のようなprefix、BEM風の`__`区切り等）を把握する。新規クラスもこのパターンを踏襲する。ファイルが存在しない場合は[component-authoring-rules.md](../../../guidelines/rules/component-authoring-rules.md)のルールに従う。

---

## STEP 3: コンポーネント・Variant単位で視覚プロパティを抽出

対象ノード配下のCOMPONENT_SET / COMPONENTを走査し、各Variantの視覚プロパティを**Variableへのバインド情報ごと**取得する。値を直接読んで既存トークンに逆引きマッチングするのではなく、`boundVariables`から紐付いている変数を特定する。

```js
// Script: コンポーネントの視覚プロパティ＋Variableバインドを取得
const nodeId = 'XXXX:XXXX'; // design-system-map.md の node-id をコロン区切りに（正本は所在マップ）
const targetNode = await figma.getNodeByIdAsync(nodeId);
if (!targetNode) throw new Error(`ノード(${nodeId})が見つかりません`);

function extractStyle(node) {
  const style = { name: node.name, type: node.type };

  // 塗り（fills）
  if (node.fills && node.fills !== figma.mixed) {
    style.fills = node.fills.map(f => ({
      type: f.type,
      boundVariable: f.boundVariables?.color?.id ?? null,
      // boundVariableがnullの場合のみ生値を参考情報として持つ（CSSには使わない）
      rawColor: f.boundVariables?.color ? null : f.color
    }));
  }

  // 角丸
  if ('cornerRadius' in node) {
    style.cornerRadius = {
      value: node.cornerRadius,
      boundVariable: node.boundVariables?.cornerRadius?.id ?? null
    };
  }

  // Auto Layoutのpadding・gap
  if (node.layoutMode && node.layoutMode !== 'NONE') {
    style.padding = {
      top: node.paddingTop, right: node.paddingRight, bottom: node.paddingBottom, left: node.paddingLeft,
      boundVariables: node.boundVariables?.paddingTop ?? null // 他のpadding系も同様に確認する
    };
    style.gap = { value: node.itemSpacing, boundVariable: node.boundVariables?.itemSpacing?.id ?? null };
  }

  // ストローク
  if (node.strokes && node.strokes.length > 0) {
    style.strokes = node.strokes.map(s => ({
      boundVariable: s.boundVariables?.color?.id ?? null,
      rawColor: s.boundVariables?.color ? null : s.color
    }));
  }

  return style;
}

const results = [];
const sets = targetNode.findAll(n => n.type === 'COMPONENT_SET');
for (const s of sets) {
  const variants = s.children.map(child => ({
    variantName: child.name, // "Size=Large, State=Default" 形式
    style: extractStyle(child)
  }));
  results.push({ componentSetName: s.name, variants });
}
return results;
```

**変数IDからトークン名への変換**: 取得した`boundVariable`（変数ID）は、`figma-guideline-sync`のScript Aで取得済みの変数一覧（`design-tokens.json`）と突き合わせて、対応するCSS変数名を特定する。ID→名前の対応が`design-tokens.json`に無い場合は、先に`figma-guideline-sync`を再実行してトークンを最新化する。

---

## STEP 4: CSSへの変換

- `boundVariable`が特定できたプロパティは、対応するCSS変数（`var(--xxx)`）で出力する
- `boundVariable`が無く生値のみのプロパティは、**CSSに直接値を書き込まない**。「要人間判断リスト」に《コンポーネント名・プロパティ・生値》を記録し、STEP6で報告する
- クラス名はSTEP2で把握した既存パターンを踏襲する。新規コンポーネントの場合は[component-authoring-rules.md](../../../guidelines/rules/component-authoring-rules.md)・[variant-naming-rules.md](../../../guidelines/rules/variant-naming-rules.md)に従う

---

## STEP 5: 既存ファイルとの差分確認

既存の`components.css`をReadし、生成結果との差分をユーザーに提示する。承認を得てから上書き保存する。

---

## STEP 6: 完了報告

```
components.css の同期が完了しました

【対象】{node-id}（{Layer 2 共通 / Layer 3 <service>固有}）
【出力先】guidelines/{kit または <service>}/components.css
【更新したクラス】{一覧}
【要人間判断】Variableに紐付いていない生値が見つかったプロパティ（該当なければ「なし」）
  - {コンポーネント名}.{プロパティ}: 生値 {値} （Figma側でVariableへの紐付けを検討してください）
【対応表】component-map.md の更新（下記）
```

**対応表の同期（STEP 5で上書き保存した場合は必ず行う）**: 更新・追加したクラスに対応する [component-map.md](../../../guidelines/kit/component-map.md) の行を node-id で探し、「CSSクラス」「動き（標準）」を直して確認日を今日にする。行が無い部品は追加する（node-id・CSSクラス・動き・確認日。バリアントは書かない）。変更箇所を完了報告の「対応表」欄に書く。

**要人間判断リストがある場合は、CSSへの反映を保留し、先に報告する。** 生値を仮でCSSに書き込まない。
