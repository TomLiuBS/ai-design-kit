# Variables / Design Token のAI-ready基準

AIが生値ではなく正しい意味Tokenを選び、Theme、Mode、Platformの差分へ安全に対応できるかを評価する基準。Token名からコード識別子への変換規則、およびリポジトリ側ミラーとの整合は I3・I2 で評価する。**Variables適用の要否・どのコレクションから選ぶか・直し方は [variables-rules.md](../../../../guidelines/rules/variables-rules.md)（[component-authoring-rules.md](../../../../guidelines/rules/component-authoring-rules.md) CA-08 の詳細）、値の規定（size・角丸・影・余白・カラー等）は [guidelines/rules/variant-naming-rules.md](../../../../guidelines/rules/variant-naming-rules.md) と共通ガイドラインを参照する。**

`範囲` 列はCoreレビューで評価する項目を示す。E1 は Variables Collection全体の参照方向を要するため、ファイル単位で見られる Claude Code版（本スキル）が担当する。

| ID | 2点の基準 | 主な確認証拠 | 範囲 |
|---|---|---|---|
| E1 Token階層 | Primitive、Semantic、Component token等の層と参照方向が定義される | Collections、Alias graph、文書 | Core |
| E2 Semantic token利用 | Color、Spacing、Typography、Radius等で用途に応じた意味Tokenを使う | Component適用値、Style、Variables | Core |
| E3 命名規則 | Collection、Group、Variable名が一貫し、用途・状態・Scopeを表す | 変数一覧、命名ルール | Ext |
| E4 Mode / Theme | Light／Dark、Brand、Platform等の必要Modeが整備され、欠損しない | Mode一覧、値欠損、切替テスト | Ext |
| E5 Alias構造 | Aliasが正本へ接続され、循環、孤立、意味逆転、不要な直参照がない | Alias chain、参照先、例外 | Ext |
| E6 適用率 | 公開Component内の生値やDetached styleが許容範囲内で、例外理由がある | 利用箇所集計、代表Component | Core |
| E7 Scopeと型 | Variableの型とScopeが適切で、不適切な候補が過剰表示されない | Type、Scope設定、選択UI | Ext |
| E8 廃止と移行 | Deprecated tokenに代替先と移行方針があり、現行資産から参照されない | Description、Alias、利用箇所 | Ext |

## 判定上の注意

- Token階層の名称は組織ごとに異なってよい。重要なのは参照方向、責務、例外が一貫していること。
- 生値を一律に0点としない。例外の目的、範囲、再利用性、Theme対応への影響を確認する。[variables-rules.md](../../../../guidelines/rules/variables-rules.md) VR-02 の違反条件に当たる生値だけを減点対象とする。VR-02 で違反にしないもの（0、同じ値の Variable がない値、ベクター系ノードの色等）は減点しない。
- Commonとアプリ固有Tokenがある場合、固有層はCommonへのAliasまたは明文化された例外として追跡できるかを見る。
- 必須のアクセシビリティ意味TokenやMode値が欠落し広範囲へ影響する場合はCritical候補とする。
- E6の適用率は実測する（[ai-ready-criteria.md](ai-ready-criteria.md) の実測手順に従う）。分母と分子、代表的な生値のサンプルを併記する。
- TokenのRenameや置換提案には、Alias移行、既存Componentと実装への影響、互換期間、回帰対象Modeを含める。
