---
name: figma-rename-layers
description: "画面要件書（mdファイル）に記載されているタイトル番号（例：3.1.1.1）を、対応するFigmaフレーム内のレイヤー名の冒頭に追記するスキル。対象フレームはFigma URLのnode-idから自動取得する。番号部分以外のレイヤー名は変更しない。実行前にユーザー確認を行う。"
disable-model-invocation: true
---

# Figma レイヤーリネームスキル（画面要件書ベース）

**MANDATORY**: `use_figma` を呼び出す前に必ず figma-use を読み込むこと。

**Always pass `skillNames: "figma-rename-layers"` when calling `use_figma` as part of this skill.**

## スキルの概要

画面要件書（mdファイル）に記載されたタイトル番号（例：`3.1.1.1`）を、
対応するFigmaフレーム内のレイヤー名の**冒頭にアンダースコア区切りで追記**する。

変更後のレイヤー名フォーマット：`3.1.1.1_元のレイヤー名`

以下のレイヤーは変更しない：
- 画面要件書に対応するタイトルが見つからないレイヤー

## 前提条件

ユーザーから以下を受け取ること。いずれかが不明な場合は実行前に確認する：

1. **画面要件書のパス**（例: `<repo>/docs/<画面要件書>.md`）
2. **FigmaファイルURL**（node-idを含むURL。例: `https://www.figma.com/design/<fileKey>/...?node-id=<nodeId>`）

対象の親フレームはURLに含まれる `node-id` パラメータから自動取得する。ユーザーへの確認は不要。

## ステップ1: 画面要件書を読み込む

指定されたmdファイルを読み込み、タイトル番号とタイトル名の対応表を作成する。

- タイトルのパターン: `3.1.1.1. カルーセルボタン` のような `番号. タイトル名` 形式
- 番号部分（例: `3.1.1.1`）のみを抽出する

抽出の正規表現例：
```
/^(\d+(?:\.\d+)+)\.\s+(.+)/
```

抽出結果の例：
```
{ number: "3.1.1.1", title: "カルーセルボタン" }
{ number: "3.1.1.2", title: "メインビジュアル" }
```

## ステップ2: FigmaURLからnode-idを取得し、対象フレームのレイヤーを取得する

URLの `node-id` パラメータを取り出し（例: `<n>-<m>` → `<n>:<m>` に変換）、
そのIDのノードを親フレームとして扱い、配下のレイヤーをすべて取得する。

```js
const NODE_ID = "<nodeId>"; // URLのnode-idを「-」→「:」に変換した値

const frame = await figma.getNodeByIdAsync(NODE_ID);
if (!frame) return { error: `node-id "${NODE_ID}" のフレームが見つかりません` };

const nodes = frame.findAll(() => true);
return nodes.map(n => ({ id: n.id, name: n.name, type: n.type }));
```

## ステップ3: 照合して変更内容をユーザーに提示する

画面要件書のタイトル名とFigmaのレイヤー名を照合し、
**変更前 → 変更後** の一覧を作成してユーザーに提示する。

照合の考え方：
- レイヤー名が既に `番号_` で始まっている場合は、番号部分を除いた文字列でタイトル名と照合する
- 照合が取れたレイヤーはすべて変更対象とする（既存の番号は正しい番号に上書きする）

提示フォーマット例：
```
以下のレイヤー名を変更します。よろしいですか？

| 変更前                       | 変更後                      |
|------------------------------|-----------------------------|
| カルーセルボタン              | 3.1.1.1_カルーセルボタン   |
| メインビジュアル              | 3.1.1.2_メインビジュアル   |
| 9.9.9_メインビジュアル       | 3.1.1.2_メインビジュアル   |  ← 既存番号の上書き例

※ 対応するタイトル番号が見つからなかったレイヤーは変更しません。
```

**ユーザーの実行指示を待つ。指示があるまで Figma への書き込みは行わない。**

## ステップ4: ユーザー確認後にリネームを実行する

ユーザーから実行の指示があった場合のみ、以下を実行する。

```js
const renameMap = [
  // { id: "NODE_ID", newName: "番号_レイヤー名" }
];

const mutatedNodeIds = [];
for (const { id, newName } of renameMap) {
  const node = await figma.getNodeByIdAsync(id);
  if (node) {
    node.name = newName;
    mutatedNodeIds.push(node.id);
  }
}

return { mutatedCount: mutatedNodeIds.length, mutatedNodeIds };
```

## ステップ5: 変更後を検証する

```js
const ids = [/* ステップ4で返したmutatedNodeIds */];
const result = [];
for (const id of ids) {
  const node = await figma.getNodeByIdAsync(id);
  if (node) result.push({ id: node.id, name: node.name });
}
return result;
```

## 照合ルール

- レイヤー名と画面要件書のタイトル名を照合する際、レイヤー名の冒頭に `番号_` がある場合はそれを除いた文字列で比較する
- 照合が取れたレイヤーはすべて変更対象（既存の番号も正しい番号に上書き）
- 対応するタイトルが見つからなかったレイヤーは変更しない（据え置き）
- 変更対象のレイヤー名フォーマット: `{番号}_{元のレイヤー名}`（アンダースコア区切り）
- 1レイヤーに対して複数の候補がある場合はユーザーに確認する

## エラーリカバリー

- エラーが起きたら即リトライせず、エラーメッセージを読む
- スクリプトは **atomic** なので、失敗しても変更は残らない

## 実行前の確認チェックリスト

- [ ] 画面要件書のパスは受け取ったか？
- [ ] FigmaファイルURL（node-id付き）は受け取ったか？
- [ ] node-idから対象フレームを正しく取得できたか？
- [ ] ステップ3の変更一覧をユーザーに提示したか？
- [ ] ユーザーから実行指示を受け取ったか？
