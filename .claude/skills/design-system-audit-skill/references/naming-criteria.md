# Naming / Layer構造 のAI-ready基準

AIが検索語から正しい資産を発見し、要素の意味と階層を安定して読み取れるかを評価する基準。**「正しい名前の形式」はルール正本に定義があり、ここでは再定義しない。** 形式の判定は [guidelines/rules/layer-naming-rules.md](../../../../guidelines/rules/layer-naming-rules.md) と [guidelines/rules/variant-naming-rules.md](../../../../guidelines/rules/variant-naming-rules.md) を参照する。

`範囲` 列はCoreレビューで評価する項目を示す。

| ID | 2点の基準 | 主な確認証拠 | 範囲 |
|---|---|---|---|
| C1 Component命名 | 役割・カテゴリ・階層が分かり、公開資産に仮名がない | Asset panel、Component名 | Core |
| C2 命名体系の一貫性 | 区切り、単複、大小文字、接頭辞、カテゴリ体系が統一される | 横断一覧、命名ルール | Ext |
| C3 検索語との一致 | デザイナーが使う業務語・UI語で目的資産を検索できる | 検索テスト、用語集、別名 | Ext |
| C4 Layer名の意味性 | 役割を表す名前を持ち、形式ルールに違反しない | Layer tree、代表Instance | Core |
| C5 Layer階層 | 視覚・意味・操作上のまとまりと階層が一致し、不要なWrapperが少ない | Layer tree、Auto Layout構造 | Ext |
| C6 PropertyとLayerの対応 | Property名と対象Layerの関係を推測でき、同義語が混在しない | Property定義、Layer名 | Ext |
| C7 状態・可視性の命名 | Hidden layerや代替状態が用途を表し、古い候補が残らない | Boolean対象、非表示Layer | Ext |
| C8 言語と略語 | 使用言語、用語、略語が統一され、組織固有語に説明がある | 用語集、Description、横断検索 | Ext |
| C9 機能の具体性 | 名前から「その要素が何をするのか」を推測でき、汎用語で用途が曖昧にならない | Layer名、Property名、テキスト内容、利用箇所 | Core |
| C10 親情報の冗長性 | 階層で自明な親情報を子の名前に重複させない | Layer tree、親子の名前比較 | Ext |
| C11 命名の粒度 | 名前に含まれる独立した概念が過剰でなく、関心事が分離されている | Layer名の語構成、兄弟との比較 | Ext |

## 責務境界 — 形式はルール正本に従う

- **形式的な命名規則**（ケース、記号、日本語、連番、数字、Figmaデフォルト名・素材名、ダミーテキスト、禁止語、綴り誤り、単独Image）の判定は [layer-naming-rules.md](../../../../guidelines/rules/layer-naming-rules.md) の R-01〜R-10 に従う。図形系の既定名（`Rectangle` 等）とフレーム内のImageは違反にしない。**本スキルで別基準を作らない。** 画面ファイルのLayer名は `figma-review-layers` に委譲し、C4の対象は **DS公開資産の内部Layer** に限定する。同スキルの結果が入手できる場合は証拠として引用する。
- **R-02の例外（業務固有語の日本語許容）の候補提示**：C4のレビュー中に、英訳すると意味が伝わりにくい業務固有の日本語Layer名を見つけた場合、即座にR-02違反として報告せず、[layer-naming-rules.md](../../../../guidelines/rules/layer-naming-rules.md) R-02の例外節にある「候補（審査待ち）」表への追加候補として本体の「要確認事項」に記載する（候補語・想定理由・検出元を添える）。許容リストへの正式追加はユーザーが判断し、承認後にユーザー自身または別作業でlayer-naming-rules.mdへ反映する。本スキルはレビュー専用のため、ルールファイルへの書き込みは行わない。
- C1（Component Set／Component名）と Property名の形式は [variant-naming-rules.md](../../../../guidelines/rules/variant-naming-rules.md)（V-06・V-07）に従う。
- **意味的な命名品質**（C9〜C11）はルールに○×を定義できないため本スキルが担う。形式が正しくてもAIが役割を判断できない名前を検出する層であり、DS全体の文脈がないと判定できない。
- 資産名が日本語である場合、コード識別子への写像は I3・I4 で評価する。ここでは言語の統一性のみを見る。

## C9〜C11 の判定基準（ルールに書けない品質観点）

形式違反ではないため、修正を強制せず改善提案として扱う。設計意図がある場合は利用者の判断を優先する。Criticalにしない。原則Minorとし、主要Componentで広範囲にAIの役割判断を妨げている場合に限りMajorとする。

### C9 機能の具体性

名前だけで「この要素は何をするのか」が推測できることを見る。

- 満たす例: `updateButton`（更新する）、`deleteConfirmModal`（削除確認）、`successToast`、`filterRow`
- 曖昧な例: `actionButton`（何をするアクションか不明）、`controlArea`（何を制御するか不明）、`dataContainer`（用途が不明）
- 判定は用途の一意性で行う。汎用語そのものを禁止せず、その位置で用途が確定できるなら満たすと判断する。
- Component propertyやVariant値で用途が確定する場合は、その対応を証拠として記録する。

### C10 親情報の冗長性

階層から自明な情報を子の名前へ重ねていないかを見る。

- 満たす例: `dataTable` の中が `scrollBar`、`headerRow`
- 冗長な例: `dataTable` の中が `tableScrollBar`、`dataTableHeaderRow`
- ただし、階層から切り離してコード側の識別子になる要素（Property対象Layer、Slot相当箇所）は、単独で意味が通る名前を優先してよい。冗長性より一意性を上に置く。

### C11 命名の粒度

名前に詰め込まれた独立した概念の数を見る。目安は2個以下。

- 満たす例: `controlArea`、`tooltip`、`filterRow`（フィルタ＋行＝2個）
- 過剰な例: `filterControlTooltip`（3個）、`tableDataScrollBar`（4個＋親情報の重複）
- 概念が増える原因が構造の不足（本来分けるべき階層が1層に潰れている）にある場合は、命名ではなく構造の指摘としてC5へ寄せる。

## 判定上の注意

- 組織の公式用語を一般語へ機械的に置換しない。検索性が弱い場合はDescriptionや用語集で別名を補う案も検討する。
- Layer名は見た目ではなく役割を優先する。同じ役割は同じ語彙を使う。
- 命名揺れの件数だけでなく、検索失敗、誤選択、Property操作の失敗へつながる範囲を証拠化する。
- Renameは既存Instance、実装名、ドキュメントリンクに影響し得る。改善案には対応表、移行順、Deprecated期間を含める。
