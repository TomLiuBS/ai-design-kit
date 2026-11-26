# Figma Variables 適用ルール

Component 内の余白・角丸・色・文字を、生値ではなく Variables / Style で指定するためのルール。

配置: `guidelines/rules/variables-rules.md`

参照元: UIデザイナー（作成時）、`design-system-audit`（E1・E2・E6・E7の判定）、`design-system-measure`（Variables適用率）

**このルールは複数の生成AI（Claude Code / Codex / Figma Agent）が参照する。** ランタイム側で別基準を定義しない。

コレクション名・グループ名（`Primitive` `Alias` `Size` `Negative`、`Brand` `Neutral` 等）は汎用の例である。導入先のFigma DSの実際の名前に置き換えて使う。

関連ルール: [component-authoring-rules.md](component-authoring-rules.md)（CA-08）

**なぜ必要か**: AIは生値（`16px`、`#252525`）から、それがDSのどの値かを判断できない。近い値を創作したり、似た色を取り違えたりする。Variables が付いていれば、AIは名前で正しい値を選べる。

**用途ごとにどの Variable を使うか（例: 小カードのpaddingは `Spacing/8`）は、共通は `guidelines/kit/DESIGN.md`、サービスごとは `guidelines/<service>/design-system.md`（任意）に書く。** この文書は、どのコレクションから選ぶかと、何を違反とするかだけを持つ。

---

## VR-00 対象範囲

| 対象 | 対象外 |
|---|---|
| DSの Component（Component Set内のVariant、単体Component）と、その中のノード | Instanceの内部（インスタンス元の Component で判定する） |
| | Instance で上書きした値（CA-09は作成時の指針であり、このルールでは判定しない） |
| | Component の外にある説明用のフレーム・Section |

---

## VR-01 どのコレクションから選ぶか

| 値 | 使うもの |
|---|---|
| 色 | `Alias` コレクション。`Alias` に同じ色がないときだけ `Primitive` |
| 余白（Padding）・Gap | `Size` コレクションの `Spacing/*`。Gap の負の値は `Negative` コレクションの `Padding/-*` |
| 角丸 | `Size` コレクションの `Radius/*`（例：`Radius/99`）。同じ値の Variable がまだ作られていない角丸は、違反にしない（VR-02） |
| 文字 | Text Style |

- **色は、全Modeで同じ色になる Alias を優先する。** `Brand/Primary` などModeで色が変わる Alias は、アプリごとに色を切り替えたい箇所だけに使う
- **どの Mode で解決するかは、対象アプリの指示に従う。** Mode は Variable ではなく、フレーム・Component に設定するもの。各 Mode は同じ扱いとし、特別な基準の Mode は設けない。**Mode の選択をAIが決めない。対象アプリが指示されていないときは、推測せずに質問する**
- **廃止したコレクション（例：`コレクション1` `Local Styles`。導入先で列挙する）は使わない・追加しない**

| ❌ 悪い例 | ✅ 良い例 |
|---|---|
| 本文テキストの色に `Primitive` の `Greyscale/Gray100` を付ける | `Alias` の `Neutral/Gray100` を付ける |

---

## VR-02 Variables を必須とする値

条件は、表の「違反とする条件」の**すべてを満たすとき**に違反とする。

| 対象 | 数え方 | 違反とする条件（すべて満たすとき） |
|---|---|---|
| 余白（Padding） | Auto Layout のフレームの上下左右を、辺ごとに数える | ・Variable が付いていない<br>・値が0でない<br>・同じ値の `Spacing/*` がある |
| Gap | Auto Layout のフレーム1つにつき、`itemSpacing`（折り返しがあるときは `counterAxisSpacing` も）を1つずつ数える | ・Variable が付いていない<br>・値が0でない<br>・均等配置（`SPACE_BETWEEN`）でない<br>・同じ値の `Spacing/*`（負の値は `Negative` の `Padding/-*`）がある |
| 角丸 | 角ごとに数える（4角を別々に） | ・Variable が付いていない<br>・値が0でない<br>・角ごとの値が混在（`mixed`）していない<br>・同じ値の `Radius/*` がある |
| 塗り色 | 表示されている SOLID の塗りごと | ・Variable・Style が付いていない<br>・全Modeで同じ色になる Alias に、同じ色（不透明度を含む）がちょうど1つある |
| 塗り色：Primitive への直付け | 表示されている SOLID の塗りごと | ・付いている Variable が `Primitive` コレクションのもの<br>・全Modeで同じ色になる Alias に、同じ色（不透明度を含む）がちょうど1つある |
| 廃止コレクションの Variable | Variable が付いている値ごと | ・付いている Variable が廃止コレクション（VR-01で廃止としたもの）のもの<br>・同じ値（色なら同じ色）の現行コレクションの Variable が、ちょうど1つある |
| 文字 | テキストノードごと | ・Text Style が付いていない<br>・Text Style が混在（`mixed`）していない<br>・同じ書式の Text Style がある（**同じ書式**＝フォント（ファミリー・スタイル）・文字サイズ・行間・字間がすべて一致） |

**違反にしないもの**（AIは推測で直さない）:

- 同じ値の Variable・Text Style がない生値（例: Padding `3`、近いが一致しない色 `#D9D9D9`、一致する `Radius/*` がまだ作られていない角丸 `99`）
- Modeで色が変わる Alias とだけ一致する色（付け替えると他アプリのModeで色が変わるため）
- 同じ色の Alias が2つ以上ある色 → 「要判断」として人に返す
- 色について、ノードの種類が VECTOR・BOOLEAN_OPERATION・POLYGON・STAR・LINE のもの（イラスト・ロゴ・アイコンの図形）
- 非表示の塗り、SOLID 以外の塗り（グラデーション・画像）
- Auto Layout でないフレームの余白・Gap、均等配置（`SPACE_BETWEEN`）の Gap
- Text Style が混在している文字、角丸が混在している角
- 線（Stroke）・影（このルールの対象外）

| ❌ 悪い例 | ✅ 良い例 |
|---|---|
| Paddingに生値 `16` を入れる | Paddingに `Spacing/16` を付ける |
| 角丸に生値 `99` を入れる（`Radius/99` がある場合） | 角丸に `Radius/99` を付ける |
| 文字の書式が一致する Text Style があるのに、付けずに文字サイズだけ指定する | その Text Style を付ける |
| Padding `0` に Variable を付けようとする | 0 は生値のままでよい |

---

## VR-03 直し方：値が変わらない付け替えだけを行う

- 違反は、**値が完全一致する Variable・Text Style に付け替えて**直す。近い値に丸めない
- 付け替えの前後で、全Modeの見た目が変わらないこと
- 一致する候補が2つ以上ある場合は、AIは選ばず「要判断」とする
- Primitive への直付けは、同じ色の Alias へ付け替える。廃止コレクションの Variable は、同じ値の現行コレクションの Variable へ付け替える

---

## VR-04 既存 Variable の値を変えない

- 既存の Variable の値は変更しない。別の値が必要なら、新しい Variable を作る
- Alias の参照先を付け替えることも、値の変更に含める
- 理由: Variable の値を変えると、その Variable が付いた全デザインが一斉に変わるため

| ❌ 悪い例 | ✅ 良い例 |
|---|---|
| `Spacing/16` の値を `18` に変える | `Spacing/18` を新しく作る |

---

## VR-05 Variable を新しく作るとき

- VR-01 の表のコレクションに置く。既存のグループ（`Brand` `Neutral` `Status` `Transparent` `Graph` `Spacing` 等の、そのコレクションにあるグループ）に入れる。新しいグループ（例：角丸の `Radius`）を作るかは人が決める
- 名前は、同じグループの既存の形式に合わせる（例：`Spacing/18`、`Radius/99`）
- Scope は用途に合わせて設定する（文字色なら `TEXT_FILL` など）。「すべて（ALL_SCOPES）」にしない
- 既存の「すべて」の Scope は、その Variable を整理するときに直す。Scope を変えても見た目は変わらない

---

## 付録：AIによるDSレビュー・測定での対応表

**ここから先はUIデザイナーが作成時に読む必要はない。**

| ルール | DSレビュー項目 |
|---|---|
| VR-01（どのコレクションから選ぶか、廃止コレクション） | E1（Token階層）／ E2（Semantic token利用） |
| VR-02（必須とする値） | E6（適用率） |
| VR-05（Scope） | E7（Scopeと型） |

---

## 更新履歴

| 日付 | 内容 |
|---|---|
| 2026-11-26 | v1.0：汎用キットとして初版作成 |
