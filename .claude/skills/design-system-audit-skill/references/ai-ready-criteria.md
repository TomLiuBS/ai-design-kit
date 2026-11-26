# AI-ready 評価基準と評価値

DSがAIに読み込める形式になっているかを、A〜Iの項目で評価する基準の総則。**「正しい形の定義（ルール）」は `guidelines/rules/` にあり、ここでは再定義しない。** このファイルは、どの項目を・どの重みで・どう評価値に落とすかを定める。

## レビューモードと範囲

各項目に `Core` または `Ext` を記す。

- **Core**: AIの誤選択・誤構築へ直接つながる項目。初回レビュー、定期レビュー、再レビューの既定範囲。
- **Ext**: Coreで低評価だった領域の深掘り、または正式なAI-ready認定時に評価する項目。

Coreレビューでは `Ext` 項目を評価しない。評価しなかった `Ext` 項目は「Core範囲外」と記し、N/Aや0と混在させず、得点計算から除外する。CoreでCriticalまたはMajorが出たカテゴリは、そのカテゴリのみExtへ拡張してよい。

### Figma内から判定できない項目は本スキル（Claude Code）が担う

Figma Agent版レビューはセクション内から見られるFigma内部の項目に限定される。次のCore項目はファイル／組織／リポジトリ単位の情報が要るため、本スキルが担当する（Figma Agent版では対象外）。

`E1`（Token階層）／ `F6`・`I5`（Code Connect・実装照合）／ `I2`（リポジトリ側ミラー）／ `I3`・`I4`（コード識別子への写像）／ `H3`（画面構築テスト）。

## 評価尺度

全チェック項目を `2 / 1 / 0 / N/A` で評価する。

| 評価 | 定義 |
|---|---|
| 2 | 基準を満たす。例外があっても意図と条件が明確で、AIが安定して扱える |
| 1 | 一部満たす。軽微な不整合、限定的な欠落、または回避可能な曖昧さがある |
| 0 | 満たさない。欠落・矛盾・誤誘導により、AIの選択や組み立てを誤らせる可能性が高い |
| N/A | 対象範囲に該当しない。理由を必ず記載する |

情報不足は原則N/Aにしない。対象に該当するが確認できなければ「未検証」として保留し、必要な追加情報を記録する。**「確認できなかった」を0点にしない。** 0点は「満たさないことを確認した」ときだけ付ける。未検証は得点計算から除外し、件数をScorecardに出す。**ただし、環境が原因の未検証（ツールのエラー・取得できない値など）が1件でもあるときは、得点率と判定を出さず「暫定」とする**（`SKILL.md` の「開始前チェック」参照）。

## 得点

N/AとCore範囲外、および **H（AI実利用テスト）の全項目** を除外して計算する（Hは得点外の参考情報。下記H節）。

```text
カテゴリ得点率（%） = 獲得点 ÷（評価対象項目数 × 2）× 100
総合得点率（%） = 全獲得点 ÷（全評価対象項目数 × 2）× 100
```

小数第1位まで表示する。総合はカテゴリ得点率の単純平均にしない。得点率はモード内で完結させ、CoreとExtendedを直接比較しない。再レビューは初回と同じモードで実施する。

| 得点率 | 判定 |
|---|---|
| 90–100 | AI-ready：安定利用可能。Minorを継続改善する |
| 75–89.9 | Mostly ready：限定運用可能。主要なMajorを解消する |
| 60–74.9 | At risk：誤用リスクあり。改善後に再レビューする |
| 0–59.9 | Not ready：AIによる自律利用を推奨しない |

Criticalが1件以上ある場合は得点にかかわらず `Not ready — Critical issue` とする。

## 重大度

得点とは別軸で付与する。レポートでは日本語ラベルを主に使い、英語を併記する。

- 🔴 **最優先（Critical）**: このまま使うと広範囲に壊れる。AIが確実に誤る。1件でもあればAI-readyではない判定。例：正本不明の競合ライブラリ、必須Semantic tokenの欠落、Commonと固有DSの未解決な矛盾、主要フローで禁止資産を採用するAI実利用結果。
- 🟠 **要対応（Major）**: 複数画面・利用者に影響し、AIが誤選択しやすい。回避に個別知識が要る。例：Variant軸の不整合、主要Componentの説明欠落、Responsive破綻、Semantic token不使用、代表Pattern欠落、主要ガイドラインが画像のみでテキスト取得できない。
- 🟡 **余裕があれば（Minor）**: 影響が限定され、基本利用は妨げない。例：局所的な命名揺れ、補足説明不足、稀な状態の例不足。

**個々の重大度は [scoring-rules.md](scoring-rules.md) の「重大度の表」で決める。** 上の定義は表の考え方の説明であり、表にない種類が出たときに表への追記を考える材料として使う。

**判断軸は「間違いの目立ちやすさ」ではなく影響範囲の広さ。** Criticalは0、Majorは0または1、Minorは1になりやすいが、影響範囲と回避可能性に基づき判断する。

**重大度は Issue で確定し、Issues / Detailed assessment / Scorecard / Executive summary の4箇所で同じ数字にする。** レポートを書き終えたら4箇所の件数を数え直す。一致しなければ提出しない。

## A. Component設計

詳細は [component-criteria.md](component-criteria.md) を読む。作成ルールの判定は [guidelines/rules/component-authoring-rules.md](../../../../guidelines/rules/component-authoring-rules.md) に従う。

| ID | チェック項目 | 範囲 |
|---|---|---|
| A1 再利用資産のComponent化 | Core |
| A2 責務と粒度 | Ext |
| A3 正本と公開状態 | Core |
| A4 Component properties | Core |
| A5 Property名と既定値 | Core |
| A6 内部構造とNested component | Ext |
| A7 Slot／拡張点 | Ext |
| A8 非推奨・置換情報 | Ext |

## B. Variant / State

詳細は [variant-criteria.md](variant-criteria.md) を読む。形式の判定は [guidelines/rules/variant-naming-rules.md](../../../../guidelines/rules/variant-naming-rules.md) に従う。

| ID | チェック項目 | 範囲 |
|---|---|---|
| B1 意味のあるVariant軸（軸で表すべき差分が名前に埋め込まれていないかを含む） | Core |
| B2 一貫した値 | Core |
| B3 Interaction state | Core |
| B4 Validation state | Ext |
| B5 組合せの完全性 | Core |
| B6 Variant爆発の回避 | Ext |
| B7 意味による分類 | Ext |
| B8 状態間の構造一貫性 | Ext |

## C. Naming / Layer構造

詳細は [naming-criteria.md](naming-criteria.md) を読む。形式（C4・C1・C7 の形式面）の判定は [guidelines/rules/layer-naming-rules.md](../../../../guidelines/rules/layer-naming-rules.md) と [guidelines/rules/variant-naming-rules.md](../../../../guidelines/rules/variant-naming-rules.md) に従い、意味的な命名品質（C9〜C11）は本スキルが担う。

| ID | チェック項目 | 範囲 |
|---|---|---|
| C1 Component命名 | Core |
| C2 命名体系の一貫性 | Ext |
| C3 検索語との一致 | Ext |
| C4 Layer名の意味性 | Core |
| C5 Layer階層 | Ext |
| C6 PropertyとLayerの対応 | Ext |
| C7 状態・可視性の命名 | Ext |
| C8 言語と略語 | Ext |
| C9 機能の具体性 | Core |
| C10 親情報の冗長性 | Ext |
| C11 命名の粒度 | Ext |

## D. Auto Layout / Responsive

| ID | チェック項目 | 2点の基準 | 範囲 |
|---|---|---|---|
| D1 Auto Layout適用 | 伸縮・反復・配置を持つ主要ContainerがAuto Layoutで表現される | Core |
| D2 Hug / Fill / Fixed | サイズ設定が意図に合い、不要な固定値や曖昧な伸縮がない | Ext |
| D3 Padding / Gap | 余白が構造として設定され、空Frameや手動位置で代用されない | Ext |
| D4 Constraints | 親サイズ変更時の固定・伸縮・整列動作が意図どおりである | Ext |
| D5 Content耐性 | 長文、複数行、空値、最大件数、ローカライズで破綻しない | Core |
| D6 Breakpoint／モード | 幅・密度・入力方式ごとの振る舞いが必要範囲で定義される | Ext |
| D7 Nested responsive | 子Componentと親Patternのリサイズ規則が入れ子でも矛盾しない | Ext |
| D8 絶対配置の制御 | Absolute positionが意図的な重なりに限定され、理由と制約を読める | Ext |

D5では、主要言語である日本語の折り返し、禁則、行長、和欧混植、および想定端末の入力方式を含めて確認する。画面ブレークポイントは Variant にせず Auto Layout で対応する方針（variant-naming-rules V-05-1）を前提に判定する。

## E. Variables / Design Token

詳細は [variable-criteria.md](variable-criteria.md) を読む。

| ID | チェック項目 | 範囲 |
|---|---|---|
| E1 Token階層 | Core |
| E2 Semantic token利用 | Core |
| E3 命名規則 | Ext |
| E4 Mode / Theme | Ext |
| E5 Alias構造 | Ext |
| E6 適用率 | Core |
| E7 Scopeと型 | Ext |
| E8 廃止と移行 | Ext |

## F. Documentation / Guideline

Descriptionの形式は [guidelines/rules/description-format.md](../../../../guidelines/rules/description-format.md) を参照する（用途（必須）／選び分け・Property・禁止（条件付き））。F1・F2 は、この形式で書かれ、かつ**用途が実質的に説明できていること、および選び分け・Property・禁止が必要な部品（類似部品がある、値名の意味が自明でない軸がある、固有の禁止ルールがある）で書かれていること**を見る。見た目の説明だけ、または「適宜」「基本的に」「デザイナーに確認」で埋まっている Description は記載ありとみなさない。

| ID | チェック項目 | 2点の基準 | 範囲 |
|---|---|---|---|
| F1 Component description | 用途（何を表示・操作するかと使う場面）が簡潔に記述され、条件に当たる場合は選び分け・Property・禁止も書かれる | Core |
| F2 When to use / not use | 採用場面が用途に書かれ、類似Componentがある場合は選び分けが両方の Description にある | Core |
| F3 Content guideline | ラベル、文体、文字数、空状態、エラー文等のルールがある | Ext |
| F4 Accessibility | コントラスト、Focus、キーボード、読み上げ名、タップ領域等の要件がある | Ext |
| F5 Behavior | Interaction、Validation、Loading、遷移、状態変化が説明される | Ext |
| F6 実装との接続 | Code Connect、コード名、仕様リンク等でデザインと実装を追跡できる | Core |
| F7 所有者と更新性 | Owner、更新日、Status、問い合わせ先が分かり、古い文書を識別できる | Ext |
| F8 例外と優先順位 | Commonとの差分、プラットフォーム例外、競合時の優先順位が明記される | Ext |

F4は「要件がガイドラインとして記述され追跡できるか」に限定する。UI個別の適合判定は `accessibility-review` に委譲する。

## G. Pattern / Example

| ID | チェック項目 | 2点の基準 | 範囲 |
|---|---|---|---|
| G1 代表Pattern | Form、Search、Navigation、Feedback等、主要タスクの再利用Patternがある | Core |
| G2 Examplesの発見性 | Examplesページ、Template等が分類され検索できる | Ext |
| G3 良い例／悪い例 | Do / Don'tが理由付きで示され、表面的な模倣を防ぐ | Ext |
| G4 状態の網羅 | Empty、Loading、Error、Partial data、Permission denied等の代表状態がある | Core |
| G5 実データ耐性 | 現実的な文言・件数・画像比率・ローカライズを含む例がある | Ext |
| G6 Patternの構造品質 | 正本ComponentとTokenを使い、Detached copyや上書きに依存しない | Ext |
| G7 選択条件 | Pattern間の使い分け、前提、禁止組合せ、代替案が説明される | Ext |
| G8 アプリ固有例 | Commonと対象アプリ固有の組合せ方・差分を追跡できる | Ext |

正しいComponentが存在しても、代表PatternがDetached copyで構築されていればAIはそれを正本として模倣する。Pattern自体の構造品質を必ず確認する。

## H. AI実利用テスト

**Hは得点に入れない（参考情報）。** 実施の有無や試し方で結果が大きく変わり、実施者ごとに得点がぶれるためである。実施した場合だけ結果を付録Eに書き、実施しなくても未検証に数えない。Hで見つかった問題がルール違反によるものなら、その違反は該当する項目（B2・F1など）で点と修正リストに反映する（Hとして別にIssueを立てない）。下表の「範囲」は、実施するときの対象を示す。

本番DSを変更せず、承認された検証場所で最低3シナリオを実施する。実施場所・承認状況・後片付けの要件は `SKILL.md` の「AI実利用テストの実施条件」に従う。プロンプト、入力資料、利用可能ライブラリ、試行回数、モデル、権限、結果を記録する。

| ID | チェック項目 | 2点の基準 | 範囲 |
|---|---|---|---|
| H1 発見テスト | 要件から正本と適切なComponent／Patternを自力で特定できる | Core |
| H2 選択テスト | 類似資産、Hierarchy、Size、Stateを条件に沿って選べる | Ext |
| H3 構築テスト | 正本Instance、Token、Auto Layoutで代表画面を構築できる | Core |
| H4 Responsiveテスト | 指定幅、長文、ローカライズ等でも意図どおり適応する | Ext |
| H5 状態テスト | Error、Loading、Disabled等を正しいPropertyで再現できる | Ext |
| H6 制約遵守テスト | 禁止事項、Deprecated資産、無効な組合せ、生値を回避できる | Core |
| H7 根拠説明テスト | 選択資産・Token・Patternと根拠ガイドラインを説明できる | Ext |
| H8 再現性テスト | 同一条件の複数試行または異なる対応AIで主要選択が概ね一致する | Ext |

H1・H6は生成を伴わない選択テストとしても実施でき、検証場所の承認がなくても実施してよい。`🚫`（V-08）付き資産をAIが回避できるかは H6 で確認し、選んだ場合は不合格とする。`🚫`が`ver`の値・Component Set名・単体Component名以外にある件数も参考値として併記する（V-08）。H3（構築テスト）は承認された検証場所がある場合のみ実施する。

## I. コード連携・機械可読性

Figma内部の品質だけでなく、AIがコードとしてDSを再現できるかを評価する。

| ID | チェック項目 | 2点の基準 | 範囲 |
|---|---|---|---|
| I1 ガイドラインの機械可読性 | 利用条件、Do / Don't、命名ルールなどが画像でなくテキストで取得できる | Core |
| I2 リポジトリ側ミラー | 正本Token、Component一覧、利用ルールがリポジトリ内の機械可読文書へ同期され、同期時点と更新責任者が分かる | Core |
| I3 識別子への写像 | Variable名・Component名からコード識別子への変換規則が定義され、往復して一意に決まる | Ext |
| I4 日本語名の扱い | 日本語の資産名・Property名に対応するASCII識別子が定義され、コード生成時に一意に決まる | Ext |
| I5 Code Connect | 主要Componentがコード実装へマップされ、Property対応を追跡できる | Ext |
| I6 アセットとフォント | アイコンの書き出し形式・命名、画像比率、使用フォントの入手可否と代替が定義される | Ext |
| I7 寸法の明文化 | Breakpoint、グリッド、余白、最小タップ領域が実装可能な具体値で示され、実値と一致する | Ext |
| I8 Motionと重なりの規則 | Duration、Easing、Elevation／z-index階層がTokenまたは規則として定義される | Ext |
| I9 状態バリアントとCSSの対応 | Component Setの状態バリアント（B3の Interaction state 軸。`style` 等）が、`guidelines/` の `components.css` の該当クラスの状態にすべて対応し、値（色・サイズ）が一致する | Ext |

- I1は「記述されているか」でなく「テキストとして取得できるか」を見る。画像のみならMajorまたはCritical候補。ガイドライン文書のページも評価対象に含め、探さずにN/Aとしない。判定にはTEXTノード数と画像ノード数を測定値として記載する。
- I2はリポジトリ側ミラー（`guidelines/` の Markdown・CSS・JSON）が未整備なら `0` または「未検証」になる。整備計画の有無で重大度を判断する。
- I3・I4は、コード生成時に名前が一意に決まるかだけを見る。業務固有の日本語軸・値（variant-naming-rules V-04-2）は対応表で解決できるかを確認する。
- I9は、Figmaのバリアント一覧（`use_figma` で名前のみ取得し、集計して持ち帰る）と、`components.css` の状態セレクタ（`:hover`・`:active`・`:focus-visible`・`:disabled`・`.is-*`）を突き合わせる。次の3種類を数え、分母（対象Component Set数・状態バリアント総数）と分子を併記する。①Figmaにあって、CSSに対応がない状態 ②両方にあるが値（色・サイズ）が違う状態 ③CSSにあって、Figmaにない状態。正本はFigmaなので、修正提案はCSS側をFigmaに合わせる形で書く。`🚫`付きのバリアントは対象外（V-08）。実例: `board_icon` の `type=text_primary` は default／hover／select の3状態だが、`.ol-toolbar__send` は default／hover のみで、hover の色（gray10／Figmaはgray20）も違う（2026-11-16）
- Figma側とリポジトリ側で値が矛盾する場合、正本がどちらか判定できないなら勝手に解決せず、Critical候補として報告する。

## 実測手順（A1・C4・D1・E6・F1記載率・Variant違反候補率）

これらは数えないと判定できない。**[design-system-measure](../../design-system-measure/SKILL.md) の測定結果（走査スクリプトは同スキルの `scripts/` にある）を、測定値の証拠として記録する。**

| ID | 測定内容 |
|---|---|
| A1 | INSTANCE ÷（INSTANCE + FRAME + GROUP）の比率。反復要素がFRAME/GROUPで手作りされていないか |
| C4 | 形式ルール違反のレイヤー数 ÷ 評価対象レイヤー数。違反種別ごとの内訳も出す |
| D1 | Auto Layout適用FRAME ÷ 全FRAME |
| E6 | 余白・Gap・色・文字ごとに、Variable/Style適用済み ÷（適用済み ＋ [variables-rules.md](../../../../guidelines/rules/variables-rules.md) VR-02 の違反）。代表的な生値のサンプルを併記（Script B の `vr02`） |
| F1（記載率） | Descriptionが空でないComponent Set・単体Component ÷ 評価対象（🚫は除外）。必須ラベル（用途）がある件数、4行・200字超の件数も参考に併記。内容の正しさは測らない（Script C） |
| A5・B1・B2・C1（違反候補率） | Variant軸名・値・Property名・Component Set名の違反候補を1件以上含むComponent単位の数 ÷ 評価対象Component数。軸名・値・Property名・Set名ごとの分母・分子と違反種別の内訳も出す。日本語の業務固有語などは違反に数えず「要確認」に分ける。最終判定は variant-naming-rules.md（Script D） |
| A4・B5・E1・E2 | Property が付いていない TEXT・INSTANCE の割合／Variant の組合せの欠け／Alias の階層／値を直接持つ変数の直接参照の割合（Script E） |

### 走査範囲を固定する（毎回同じ数字が出る前提）

再レビューで Before / After を比較するため、走査範囲を回ごとに変えない。次を固定し、Scopeに必ず記録する。

| 項目 | 規定 |
|---|---|
| 起点 | 対象セクションのノード（所在マップの node-id） |
| 深さ | 制限しない。対象セクション配下を全階層走査する |
| COMPONENT / COMPONENT_SET の内部 | 走査する（AIがProperty・構造を読み取る対象のため） |
| INSTANCE の内部 | 走査しない（リネーム不可・名前はメイン由来） |
| 非表示レイヤー | 走査する（状態の出し分けに使われ実装対象になる） |

### 除外と記録

除外したノードは種別ごとに件数を記録する。除外基準を回ごとに変えない。

- 除外: INSTANCE内部 ／ TEXTノードの自動命名（C4で違反に数えない）／ Property キーの内部ID（`#`以降）／ COMPONENT・COMPONENT_SET名（C1で評価）。
- 記録形式は**分母と分子の両方**を書く。比率だけを書かない。再レビュー時は前回の分母を併記し、分母が変われば得点を比較しない。

```text
C4: 評価対象 390ノード / 違反 63件（16.2%）
    除外: INSTANCE内部 310、TEXT自動命名 10、COMPONENT名 3
D1: 全FRAME 282 / Auto Layout適用 265（94.0%）
```

測定値は [scoring-rules.md](scoring-rules.md) の換算表（暫定値）で点にする。測定値と、当てはめた表の行の両方を残す。

## 新出の共通軸候補を報告する

variant-naming-rules V-04-2 の共通軸リストは、レビューを重ねて育てる。新しい軸が出たら、次の基準で扱い、**昇格は人が判断する**ため「新出の軸候補」として別掲する。

| 出現状況 | 扱い |
|---|---|
| 2DS以上で同じ用途 | 共通軸への昇格候補として報告 |
| 1アプリ限定・業務固有 | 日本語許容のまま。昇格しない |
| 1アプリだが明らかに汎用 | 「要確認」として報告し、判断を仰ぐ |

無条件に共通軸へ足さない。レビュー側でルールを書き換えず、`guidelines/rules/variant-naming-rules.md` への追記提案として要確認事項に挙げる。
