# PROTOTYPE.md — コードプロトタイプ・デザインハーネス 共通ルール

Epic/Feature/画面骨子からHTMLプロトタイプを生成する際の最低限ルール。全体の進め方は `docs/` の資料を参照。

このファイルは`prototype-draft`スキルから必ず読み込まれる。担当者が変わっても同じ基準で作るための土台であり、ここに書かれたルールを恣意的に緩めない。

---

## 1. 技術スタック（固定）

- 素のHTML + CSS + バニラJS（フレームワーク・外部JSライブラリは使わない）
- 見た目は`<link>`でCSSファイルを参照する（インライン`<style>`への値の直書きは禁止）
- アイコン: Material Icons（`<span class="material-icons">icon_name</span>`）
- フォント: `guidelines/kit/DESIGN.md` で決めた書体（`<DESIGN.md で決めた書体>`）を、DESIGN.md に書かれた読み込み方法（Google Fonts 等）で読み込む
- 画面固有のレイアウトのみ`prototype.css`に記述し、色・余白・フォントサイズの値は書かない
- 状態切り替えはCSSクラスの付け外しで表現し、インラインスタイルの動的書き換えは避ける（`prototype.js`）

---

## 2. 参照の優先順位（必須）

1. **デザインシステムの正本はFigma**。`guidelines/` はFigmaの写しとして、定義があるものは必ずそれに従う。役割は、`guidelines/kit/DESIGN.md`＝判断のルール（使い分け・組み合わせ・罫線・ライティング）、`guidelines/<service>/design-system.md`＝サービス固有のルール（任意。ある場合は DESIGN.md より優先）、`guidelines/kit/component-map.md`＝部品とCSSクラスの対応、`guidelines/kit/design-tokens.json/css`・`guidelines/kit/components.css`＝見た目の値。ただしFigmaと差分がある場合は**Figmaが正**であり、guidelinesのCSSをFigmaに合わせて修正する（画面側の`prototype.css`での上書きで済ませない。詳細は[skills/prototype-draft/SKILL.md](skills/prototype-draft/SKILL.md) STEP2）
2. **`external/<service>/`（実装コード。任意）は補完用**。参照するのは以下の場合のみ：
   - DSに定義がないビジュアル
   - DSには表現されない挙動・ロジック（バリデーション、状態遷移など）
3. 実装コードの見た目とDSが食い違う場合は**DSを優先**する
   - FigmaとDSのCSSの差分は、「デザインシステムに合わせて」という指示があったとき（または部品が未定義のとき）に、**使う部品だけ**確認する（[SKILL.md](skills/prototype-draft/SKILL.md) 2-c）。定期スキャンはしない
4. `external/`を読む際は全文を読まず、`Grep`等で必要な箇所だけをピンポイント検索する（同期用のインデックスファイルは作らない）

DSの所在（Figmaの fileKey・ページ・node）は `guidelines/design-system-map.md` にまとめてある。

---

## 3. コンポーネント・トークン必須ルール

- 色・余白・角丸・フォントサイズなどの値は必ず`guidelines/kit/design-tokens.css`のCSS変数（`var(--xxx)`）を使う。生値（`#3399ff`や`16px`など）の直書きは禁止
- コンポーネントは`guidelines/kit/components.css`（サービス固有の上乗せがある場合は`guidelines/<service>/components.css`も）に実在するクラスのみ使う。似ていそうという感覚での自作・代替は禁止
- 該当する変数・コンポーネントが本当に存在しない場合のみ、2で定めた優先順位に従い実装コードを確認する

---

### 3-2. FigmaのDSに無い部品は、GitHubのCSSに暫定追加する

プロトタイプで必要な部品が component-map に「未定義」で、FigmaのDS（共通・サービス固有）にも見つからないとき（別のFigmaファイルの画面にだけ描かれている、など）。

- **`prototype.css` に自作しない。** `guidelines/kit/components.css`（サービス固有の部品なら`guidelines/<service>/components.css`）の末尾に専用の区画を作って追加する（`prototype.css` に置くと、他のプロトタイプで使えず見た目が分かれる）
- 区画の見出しコメントに、**【暫定: FigmaのDSに未定義】**・元にしたFigmaのノード・記録先（`generated/docs/ds-content-fix-memo.md`）を書く。色・余白・文字は `design-tokens.css` の変数で書く
- `component-map.md` に行を足す（CSSクラス欄に「**【暫定】**」、node-id は元にしたノード）
- **`ds-fix-memo` で修正メモに記録する**（FigmaのDSに登録するやることとして残す。行案を見せて承認を得る）
- FigmaのDSに部品が登録されたら、Figmaに合わせてCSSを直し、「暫定」の注記と component-map の「【暫定】」を外す（`figma-components-css-sync`）
- `guidelines/` を別リポジトリで管理している場合は、CSSを直したら guidelines 側でもコミット・プッシュする（このリポジトリのコミットとは別）

## 4. 状態網羅ルール

- 画面ごとに、起こりうる状態（空・1件・多件・エラー・権限差・入力中・送信中・成功など）を**指示がなくても提案**する
- チェック内容は[reference/state-checklist.md](skills/prototype-draft/reference/state-checklist.md)と[reference/screen-type-presets.md](skills/prototype-draft/reference/screen-type-presets.md)に従う
- 検討した上で「該当なし」と判断した状態は、省略せず「検討して該当なしと明記」する

### 4-2. 部品の状態は、元のComponentSetで確認する（初版でも修正でも）

- 押す・開く・選ぶ・入力するなど状態が変わる部品は、component-map に載っていても、その部品の**元のComponentSet**（Figmaの画面にあるInstanceの親）のバリアント名を読み、状態の軸（`style` の default／hover／select／disable など）を一覧にする。読むのはバリアント名（`get_metadata`）と、画面で使う状態のバリアントだけ。ページ全体は読まない（6-2）
- 一覧を `components.css` の該当クラスの状態（`:hover`・`.is-active`・`:disabled` など）と突き合わせる。**Figmaにあってクラスにない状態、値が違う状態**は、作る（直す）前に仕様表の「状態一覧」へ載せる。見た目で気づいてからでは遅い
- クラスに足りないときは、2の1のとおり `guidelines/kit/components.css`（または `guidelines/<service>/components.css`）をFigmaに合わせて直す。`prototype.css` の上書きで済ませない。guidelines を直せない事情があるときだけ上書きとし、その画面の `NOTES.md` に「DSとの差」として残す
- 例: 「承認する」ボタンの元のComponentSetが `type=primary` で default／hover／select の3状態を持つのに、DSのCSSには default／hover しかなく、hover の色もFigmaと違っていた、という差はここで見つける

---

## 5. 入力の受け取り方

Epic/Feature/画面骨子は以下のテンプレートで受け取る（入力元・形式は今後整備予定の暫定版）。

```md
## Epic
（プロダクトの方向性・施策の目的・背景・課題）

## Feature
（Epicをどう実現するか。具体的な機能・ユーザーストーリー）

## 画面骨子
- 対象サービス:（common / <service> 等）
- 画面の目的:
- 主要コンテンツ:
- 主要操作:
- 既存の類似画面（あれば）:
```

不明点がある場合は、生成を始める前に一度にまとめて質問する。

---

## 6. 実装手順

生成・レビューの具体的な手順は[skills/prototype-draft/SKILL.md](skills/prototype-draft/SKILL.md)に従う。要点のみここに記す：

- 生成・レビューは**同一スレッド内で完結**させる。画面ごとにsubagentを都度起動しない（プロンプトキャッシュを活かし、トークン消費を抑えるため）
- subagent（Agentツール）を使うのは、実装コードを広く調査する必要があるときだけに限定する。専用のsubagent定義ファイルは持たず、既存の`Explore`エージェントを使う
- 複数画面・複数人が同時に使う場合でも、既定ではマルチエージェント並列実行（Workflow機能）を使わない
- Figma・GitHubからの同期は非定型業務であり、人間が明示的に指示したときだけ実行する。プロトタイプ生成の都度は同期しない

### 6-2. トークン節約ルール（履歴を太らせない）

目的は、Figma・画面の確認結果をメインの履歴に溜めず、同じ質問・同じ確認を繰り返さないこと。

**Figmaを読む前に**
- 部品は[component-map.md](../guidelines/kit/component-map.md)を先に引く。**載っている部品はFigmaを読まない**。載っていない部品だけ、必要なノードに絞って読む
- DSの名前（layer名・componentSet名）が未整備の場合は信用しない。部品の同定は**node-id**を鍵にする
- Figmaで新しく確認した部品は、作業の最後に component-map.md へ書き戻す（node-id・CSSクラス・標準の動き・確認日。バリアントは書かない）。次の画面から読まずに済ませるため。表の保守の決まりは component-map.md の「保守」節に従う（確認日が30日より前の部品は、使うときにメタデータだけ照合する）
- `get_design_context` / `get_metadata` は対象ノードを絞って呼ぶ。ページ全体や画面全体に対して呼ばない

**着手前に1回で質問を出し切る**
- 生成前に「画面仕様表」を人に見せる。項目は 部品（node-id・対応クラス）／状態一覧／押せる・押せない／component-mapに無い部品／仮データになる箇所
- 質問はこの時点でまとめて1回で出す。生成後に小出しで聞かない
- 決定事項のうち、他の画面にも効くものはこのファイルか`reference/`へ、その画面だけのものは`NOTES.md`へ書く

**読み方・確認の仕方**
- `index.html`・CSS・JS・`external/`は全文を読まず、`Grep`と行範囲指定で必要な箇所だけ読む
- 次のファイルは**全文を読まない**（1ファイルで十数万文字になることがあり、プロトタイプ1本で数万〜数十万トークンを消費しうる）
  - `assets/**/*.svg`：向きや大きさは`viewBox`（先頭数行）だけ見る。見た目の確認は画像として表示して行う
  - `*-motion.css`：`Grep`でクラス名（`.m-…`）・`@keyframes`名を探し、該当行だけ読む。Figma出力の再生成物なので、手で全体を読んで編集しない
  - `*.png`：テキストとして読まない（画像として開く場合も必要な1枚だけ）
- ファイルを読む前に`wc -c`などでサイズを確認し、約3万文字を超えるものは`Grep`か行範囲指定にする
- スクリーンショットは縮小（scale 0.5程度）で撮り、見た目の確認は「初版の完成時」と「最終確認」の2回を基本にする
- 構造・文言・状態の確認は、スクリーンショットではなく`read_page`・`find`・`javascript_tool`（DOMのテキストや計算済みCSS）で行う。修正のたびに撮り直さない
- ブラウザの確認結果（スクショ・DOM）は、確認ごとに「OK／直した点」を1〜2行で書いて次に進む。同じ画面を同じ観点で撮り直さない

**セッションの区切り**
- 「①仕様表づくり → ②初版生成 → ③修正の往復」の区切りごとに、決定事項を`NOTES.md`へ書き出してから新しいセッションで続ける
- 履歴が約15万トークンを超えたら、`NOTES.md`へ書き出して新しいセッションにする（または`/compact`）
- ③の修正は「この部品をこう直す」という局所指示で行い、毎回Figma全体を読み直さない

---

## 7. レビュー

- 判定基準は[reference/review-checklist.md](skills/prototype-draft/reference/review-checklist.md)の固定項目に基づく（主観判断はしない）
- 違反があれば差し戻す。差し戻しループは**上限2回**とし、超えたら残件リストとともに人間に返す

---

## 8. 出力

- フォルダ名・エントリファイル名は[CLAUDE.md](CLAUDE.md)の「プロトタイプの命名」に従う（`<画面名>_<施策名>/index.html`）
- 保存先は`generated/prototypes/<service>/<プロト名>/<バージョンのフォルダ名>/`（`.claude/CLAUDE.md`の生成物ルールに準拠）
- 既存プロトタイプの修正依頼のときだけ、同じプロト名の下に新しい版（`-v2`等）を作る。新規の画面は新しいプロト名のフォルダにする。既存ファイルは明示的な置換指示がない限り上書きしない
- 不採用案・一時ファイルは残さない

---

## 9. 参照索引

| 参照先 | 内容 |
|---|---|
| [skills/prototype-draft/SKILL.md](skills/prototype-draft/SKILL.md) | 生成・レビューの手順書 |
| [skills/prototype-draft/reference/golden-sample.md](skills/prototype-draft/reference/golden-sample.md) | 模範画面（HTML構造の型） |
| [skills/prototype-draft/reference/state-checklist.md](skills/prototype-draft/reference/state-checklist.md) | 状態網羅チェックリスト |
| [skills/prototype-draft/reference/screen-type-presets.md](skills/prototype-draft/reference/screen-type-presets.md) | 画面タイプ別の状態テンプレ |
| [skills/prototype-draft/reference/review-checklist.md](skills/prototype-draft/reference/review-checklist.md) | レビュー判定基準 |
| `../guidelines/kit/` | デザインシステム本体（DESIGN.md・design-tokens・components.css） |
| `../guidelines/kit/component-map.md` | 部品 ⇔ CSSクラス ⇔ Figmaの場所 ⇔ 標準の動き（作る前に最初に引く。「未定義」は自作せずDSに追加） |
| `../guidelines/<service>/` | サービス固有の上乗せ（任意） |
| `../guidelines/design-system-map.md` | DSの所在（fileKey・ページ・node） |
| `../external/<service>/` | 実装コード（任意。補完用、都度全文は読まない） |
