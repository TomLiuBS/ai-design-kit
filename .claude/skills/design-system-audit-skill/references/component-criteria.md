# Component設計 のAI-ready基準

AIがComponentの役割、選択条件、変更可能範囲、正本を理解できるかを評価する基準。対象はDS本体の公開資産とし、画面ファイル側のInstance利用状況は `figma-ai-review` の担当とする。**Component作成の「あるべきルール」はルール正本に定義があり、ここでは再定義しない。** 作成ルールの判定は [guidelines/rules/component-authoring-rules.md](../../../../guidelines/rules/component-authoring-rules.md)（CA-01〜CA-09）を参照する。

`範囲` 列はCoreレビューで評価する項目を示す。

| ID | 2点の基準 | 主な確認証拠 | 範囲 |
|---|---|---|---|
| A1 再利用資産のComponent化 | 反復利用するUIがComponent化され、使い捨てFrameと区別できる | 公開資産一覧、画面内の反復要素、Detached copy | Core |
| A2 責務と粒度 | 責務が一貫し、巨大すぎる複合部品や過度な細分化がない | 入出力、Nested構造、利用箇所 | Ext |
| A3 正本と公開状態 | 正式版、試験版、Deprecatedが明確で、同用途の正本を特定できる | Library公開状態、Status、説明、重複名 | Core |
| A4 Component properties | Text、Boolean、Instance swap、Variant等で許可された変更を公開する | Property定義、Instance override | Core |
| A5 Property名と既定値 | 名前が意味を表し、既定値が代表的かつ安全である | Property名、型、既定値、説明 | Core |
| A6 内部構造とNested component | 再利用すべき内部要素が共通化され、差替え可能範囲が明確である | Nested instance、公開Property、構造差 | Ext |
| A7 Slot／拡張点 | 必要な差替え・拡張方法と制約が明示される | Slot相当箇所、Instance swap、許容例 | Ext |
| A8 非推奨・置換情報 | Deprecated資産に理由、代替先、移行条件がある | Description、命名、移行資料、現行参照 | Ext |

## 責務境界 — 作成ルールはルール正本に従う

- バージョン・世代を名前やVariant値に入れない（CA-01）、分類を名前に詰め込まず軸で表す（CA-02）、同役割の重複を作らない（CA-03）、軸の意味を取り違えない（CA-07）、余白等のVariables適用（CA-08。判定条件は [variables-rules.md](../../../../guidelines/rules/variables-rules.md)）、インスタンスを編集しない（CA-09）といった作成ルールの判定は [component-authoring-rules.md](../../../../guidelines/rules/component-authoring-rules.md) に従う。**本スキルで別基準を作らない。**
- A4（公開Property の範囲）と A5（Property名・既定値の質）を切り分ける。A4は「変えるべき箇所がPropertyになっているか、不要なPropertyがないか」、A5は「Property名がASCII英語の意味名で読めるか、既定値が安全か」。Property名の形式は [variant-naming-rules.md](../../../../guidelines/rules/variant-naming-rules.md) V-07 に従う。**名前の質を A4 で評価しない。**

## CA違反 → 評価項目の対応

[component-authoring-rules.md](../../../../guidelines/rules/component-authoring-rules.md) の各ルールへの違反は、次の項目で検出する。

| CA違反 | 内容 | 評価項目 |
|---|---|---|
| CA-01 | バージョン・世代が名前・値に埋め込まれている | B2（Variant値）／ C1（Component名） |
| CA-02 | 分類が名前に詰め込まれ、軸が使われていない | **B1（Variant軸の設計）** |
| CA-03 | 同役割の重複 | A3（正本と公開状態） |
| CA-04 | 軸名・値・名前のルール違反 | A5 / B1 / B2 / C1 / C4 |
| CA-05 | Description が空 | F1 / F2 |
| CA-07 | 軸の意味の取り違え（`state`に種別・表示内容を入れる等） | B1 |
| CA-08 | Variables 未適用（判定条件は [variables-rules.md](../../../../guidelines/rules/variables-rules.md) VR-02） | E2 / E6 |
| CA-09 | インスタンスの編集（Detached copy 化） | A1 / G6 |

## 判定上の注意

- Component数の多さや少なさだけで評価せず、再利用範囲と変更契約が明確かを見る。
- Propertyを増やすこと自体を改善としない。AIが安全に変更すべき差分だけを公開できているかを重視する。
- A3で正本を特定できず主要フローへ広く影響する場合はCritical候補とする。
- Deprecated資産が残ること自体では減点せず、状態・代替先・移行計画・現行利用の有無で判断する。`🚫` で識別できている状態（`ver`の値・Component Set名・単体Component名）は減点しない（V-08）。それ以外の位置の`🚫`は指摘する。
- アプリ固有DSでは、共通DSを **Instance参照か複製か** を区別する。複製（Detached copy含む）は追随しないため、アプリ固有DS側のIssueとし、共通DSへの統合可否を提案する。
- 内部実装の変更提案では、既存Instance、Overrides、Code componentへの影響と移行策を示す。
