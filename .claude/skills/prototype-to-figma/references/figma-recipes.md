# `use_figma` のレシピと落とし穴

呼ぶ前に `figma-use` と `figma-generate-design` を読み込み、`skillNames` に両方を入れる。ここには、このスキルで繰り返し使う書き方だけを置く。

## 落とし穴（実際に起きたこと）

| 起きたこと | 原因 | 防ぎ方 |
|---|---|---|
| 「ノードが存在しない」エラーで、置換が途中で止まる | 先に `findAll` で作った一覧に、置換で消した子ノードが残っていた | **部品の種類ごとに、置換の直前に `root.findAll` で探し直す。** 一覧を使い回さない |
| 置換したあとの `.name` の参照でエラーになる | 消したノードの名前を読んだ | 名前・位置・サイズは、**`remove()` の前に控える** |
| 置換したのに位置がずれる | 自動レイアウトの親にインスタンスを入れると、配置の設定が変わる | 親の `counterAxisAlignItems` などを元に戻す。置換前後の `x / y` を比べる |
| `layoutAlign = 'CENTER'` が効かない | インスタンスでは反映されないことがある | 親の `counterAxisAlignItems = 'CENTER'` を設定する |
| アイコンが歪む | キャプチャのアイコン枠（例：11×16）に合わせて `resize` した | アイコンは `resize` せず、標準サイズで枠の中央に置く |
| エラーのあと、状態がどうなったか分からない | 1回の呼び出しの途中で失敗した | 失敗した呼び出しは巻き戻されることが多いが、**再実行の前に、対象の件数を数えて確かめる**。再実行しても二重に置換されないよう、対象は「まだ置換していないフレーム」（`type === 'FRAME'` など）で絞る |

## 置換の共通関数

```js
// 置換前の位置・サイズ・名前・透明度を控え、同じ場所にインスタンスを入れて、古いノードを消す
function swapIn(old, inst) {
  const p = old.parent;
  const idx = p.children.indexOf(old);
  const before = [old.x, old.y, old.width, old.height];
  const name = old.name, opacity = old.opacity;
  const absolute = p.layoutMode === 'NONE' || old.layoutPositioning === 'ABSOLUTE';
  p.insertChild(idx, inst);
  if (absolute) { try { inst.layoutPositioning = 'ABSOLUTE'; } catch (e) {} inst.x = before[0]; inst.y = before[1]; }
  inst.name = name; inst.opacity = opacity;
  old.remove();
  return before;           // 戻り値を、置換前後のサイズ表に使う
}
// 置換前後の寸法を種類ごとに集計する（例：'24x24 → 24x24 ×20'）
const rec = (log, cat, b, inst) =>
  (log[cat] ||= []).push(`${Math.round(b[2])}x${Math.round(b[3])} → ${Math.round(inst.width)}x${Math.round(inst.height)}`);
```

- 種類ごとに `const targets = root.findAll(n => n.type === 'FRAME' && 条件)` と書き、その場で置換する
- variant は `componentSet.children.find(c => c.name === 'type=…, size=…, state=…')` で選ぶ（名前のカンマの後ろにスペースがある）
- アイコンの差し替えは、`inst.setProperties({ [キー]: アイコンのコンポーネントid })`。キーは `Object.keys(inst.componentProperties)` から `startsWith('icon#')` などで探す

## 正本のFigmaでの実使用サイズの集計（読み取りのみ）

```js
const page = await figma.getNodeByIdAsync('<正本のページid>');
await figma.setCurrentPageAsync(page);                       // ページの切り替えは1回だけ
const want = /^(button|selectField|iconButton|toggleSwitch|radiobutton|checkbox|drawerButton)$/;
const rows = {};
for (const i of page.findAllWithCriteria({ types: ['INSTANCE'] })) {
  const m = await i.getMainComponentAsync(); if (!m) continue;
  const set = m.parent && m.parent.type === 'COMPONENT_SET' ? m.parent.name : m.name;
  if (!want.test(set)) continue;
  const k = `${set} | ${Math.round(i.width)}x${Math.round(i.height)}`;
  rows[k] = (rows[k] || 0) + 1;
}
return rows;   // 例：'button | 186x48': 1, 'selectField | 172x40': 8
```

- 調べたいコンポーネント名を `want` に入れる
- 正本のページは、複数の画面を含む大きなページのことがある。**ページ全体を一度に調べるのは1回まで**にし、結果を保存して使い回す

## レイヤー名の違反の検証（読み取りのみ）

[layer-naming.md](layer-naming.md) の「検証」を実行するときの書き方。

```js
const shape = /^(Rectangle|Line|Arrow|Ellipse|Polygon|Star|Vector|Path|Union|Subtract|Intersect|Exclude)( \d+)?$/;
const banned = /(^|[a-z])(Group|Section|Wrapper|Box|Block|Row|Col)([A-Z]|$)|^(group|section|wrapper|box|block|row|col)/;
const bad = [];
for (const n of root.findAll(() => true)) {
  if (n.id === root.id || n.type === 'TEXT' || shape.test(n.name)) continue;
  let p = n.parent, inside = false;
  while (p && p.id !== root.id) { if (p.type === 'INSTANCE') { inside = true; break; } p = p.parent; }
  if (inside) continue;                                     // インスタンスの内部は対象外
  if (!/^[a-z][a-zA-Z0-9]*$/.test(n.name) || banned.test(n.name) || /\d/.test(n.name)) bad.push(`${n.id} "${n.name}"`);
}
return { badCount: bad.length, bad };
```
