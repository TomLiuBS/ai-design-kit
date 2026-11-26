# Variant / State のAI-ready基準

AIが可能な状態を発見し、有効な組合せを選び、状態間で安定して操作できるかを評価する基準。**軸名・値・Property名の「正しい形式」はルール正本に定義があり、ここでは再定義しない。** 形式の判定は [guidelines/rules/variant-naming-rules.md](../../../../guidelines/rules/variant-naming-rules.md)（V-01〜V-08）を参照する。

`範囲` 列はCoreレビューで評価する項目を示す。

| ID | 2点の基準 | 主な確認証拠 | 範囲 |
|---|---|---|---|
| B1 意味のあるVariant軸 | 軸が用途・意味を表し、Variantで表すべき差分が名前に埋め込まれていない | Property名、値、Component Set名、利用ガイド | Core |
| B2 一貫した値 | 値の語彙・表記がComponent set内・DS全体でルールどおり一貫する | set間比較、大小文字、同義語 | Core |
| B3 Interaction state | 対象プラットフォームに必要なDefault、Hover、Pressed、Focus、Disabled等を備える | Variant一覧、Prototype、ガイド | Core |
| B4 Validation state | Error、Warning、Success、Read-only等、必要状態と利用条件がある | フォーム資産、説明、Examples | Ext |
| B5 組合せの完全性 | 有効な組合せを再現でき、無効な組合せと制約が明示される | Variant表、欠損組合せ、禁止条件 | Core |
| B6 Variant爆発の回避 | 表示・文言差分はBoolean、Text、Instance swap等の適切なPropertyで扱う | Variant数、Property設計、重複構造 | Ext |
| B7 意味による分類 | `Blue`や`40px`ではなく`Primary`や`Medium`等の意味名を使う | Variant値、Tokenとの対応 | Ext |
| B8 状態間の構造一貫性 | 状態間でProperty、Layer名、Nested instanceが不必要に変化しない | Variant構造比較、override保持 | Ext |

## 責務境界 — 形式はルール正本に従う

- 軸名（`state`統一など）、値の表記・言語・バージョン、Property名、Component Set名の形式は [variant-naming-rules.md](../../../../guidelines/rules/variant-naming-rules.md)（V-04・V-05・V-06・V-07）に従う。size・角丸・影の値は V-01〜V-03。**本スキルで別基準を作らない。**
- **表記の揺れは、意味が通っていても違反とする。** AIは文字列で軸名・値を指定するため、`state` と `status` は別物になる（B2）。
- 比較の順序は ①ガイドラインの規定 → ②共通DSの同種Component → ③対象セクション内。上位に規定があればそれが正本。規定に合っている値を「少数派だから」で違反にしない。
- `🚫`（非推奨マーカー、V-08）が`ver`の値・Component Set名・単体Component名にある場合は**違反としない**が、AIの選択対象から外す。それ以外の軸の値にある`🚫`はV-08違反として指摘する（並存は要判断。削除・統合は提案しない）。`仮` を含む値は意味未確認のため「要確認」とする。

## B1 の拡張 — 軸で表すべき差分が名前に埋め込まれていないか

B1は「軸が意味を表すか」に加えて、**サイズ・状態・種別などの差分が、Variant軸ではなく名前（`/`区切りやアンダースコア）に詰め込まれていないか**を見る。これは [component-authoring-rules.md](../../../../guidelines/rules/component-authoring-rules.md) CA-02 に対応する。

- 問題例: `新ポータル_2.0期/lg_申請/Unselected/共通` のように、世代・サイズ・種別・状態が名前に埋め込まれ、軸が使われていない。
- あるべき姿: Component `requestCard` の Variant軸 `size=large` `contentType=request` `state=unselected`。
- **これはリネームで直らない構造問題である。** 機械的変換の対象にせず、「要判断（Variant軸への作り直し）」として修正リストに回す。軸の追加・分離は既存Instanceが新軸の既定値になるため、既存デザインへの影響「あり」とする。

## 判定上の注意

- 対象プラットフォームに存在しない状態はN/Aにできるが、理由を記録する。
- 全組合せを物理的に用意することを要求しない。必要状態を再現でき、無効な組合せをAIが避けられることを重視する。
- 見た目だけ異なる値名は、Semantic tokenや用途名へ接続できるか確認する。
- Variant軸の変更提案では、Instanceの選択値、実装API、Code Connect、移行時の互換性を確認する。
- B2は他セクションとの比較が必要。対象セクション内だけで揃っていても、DS全体で揃っていなければ2点にしない。突き合わせできない場合は確認できた範囲を明記する。
