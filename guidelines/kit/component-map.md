# component-map.md — 部品の索引（テンプレート）

AIが画面を作るとき、**部品を探す最初の場所**です。Figma の部品 ⇔ CSS のクラス ⇔ 標準の動き を1行で引けるようにします。

- Figma の場所は `design-system-map.md` のファイル・ページと、部品の node-id で書く（`<nodeId>`）。
- 「確認日」から **30日を過ぎた行**は、使う前に Figma と照合し直し、確認日を更新する。
- ここにない部品は作り込まず、「素材に不足」として報告する。仮で CSS に足したら「仮」と書き、修正メモに記録する。

| 部品 | Figma の名前 | Figma の場所 | CSS クラス | Variant（軸：値） | 標準の動き | 確認日 |
|---|---|---|---|---|---|---|
| ボタン | `button` | `<nodeId>` | `.btn` `.btn--primary` `.btn--secondary` `.btn--text` `.btn--small` `.btn--large` | type: primary / secondary / text、size: small / medium / large、state: normal / hover / pressed / focused / disabled | 押すと処理を実行。処理中は disabled にして連打を防ぐ | `<YYYY-MM-DD>` |
| 入力欄 | `textField` | `<nodeId>` | `.field` `.input` `.field__label` `.field__help` `.field__error` | state: normal / focused / filled / error / disabled | エラーは送信時と離れたときに表示。エラー文は欄の下 | |
| セレクト | `select` | `<nodeId>` | `.select` | state: normal / focused / error / disabled | 選んだだけで画面を移動しない | |
| チェックボックス | `checkbox` | `<nodeId>` | `.check` | state: selected / unselected / partiallySelected / disabled | ラベルも押せる | |
| ラジオ | `radio` | `<nodeId>` | `.radio` | state: selected / unselected / disabled | ラベルも押せる | |
| テーブル | `table` | `<nodeId>` | `.table` `.is-number` | density: `<…>`、行 state: normal / hover / selected | 数値は右寄せ。行を押すと詳細へ（行全体が押せる） | |
| カード | `card` | `<nodeId>` | `.card` `.card__title` `.card--link` | state: normal / hover / selected | — | |
| ヘッダー | `header` | `<nodeId>` | `.header` `.header__title` | — | 画面のタイトルを表示 | |
| サイドメニュー | `sideNav` | `<nodeId>` | `.nav` `.nav__item` | state: current / notCurrent | 現在の画面を `is-current` で示す | |
| タブ | `tabs` | `<nodeId>` | `.tabs` `.tabs__item` | state: current / notCurrent | 切り替えても入力中の値を消さない | |
| ダイアログ | `dialog` | `<nodeId>` | `.dialog-overlay` `.dialog` `.dialog__title` `.dialog__body` `.dialog__actions` | type: confirm / form | 閉じるボタンと Esc で閉じる。取り消せない操作の確認に使う | |
| トースト | `toast` | `<nodeId>` | `.toast` | type: success / error | 保存・送信の結果を数秒表示 | |
| バナー | `banner` | `<nodeId>` | `.banner` `.banner--success` `.banner--warning` `.banner--error` | type: info / success / warning / error | 閉じるまで残る注意・お知らせ | |
| 空状態 | `emptyState` | `<nodeId>` | `.empty` `.empty__title` | — | 理由と次にすることを表示 | |
| 状態表示 | `status` | `<nodeId>` | `.status` `.status--success` `.status--warning` `.status--error` | type: success / warning / error | 色と文字の両方で示す | |

## アイコン

| 項目 | 記入欄 |
|---|---|
| アイコンのセット | `<例：Material Symbols Outlined／lucide>` |
| サイズ・線の太さ | `<例：20px・1.5px>` |
| 独自アイコンの置き場所 | `guidelines/kit/icons/`（必要になったら作る） |

## 更新履歴

| 版 | 日付 | 変更内容 | 変更者 |
|---|---|---|---|
| v0.1 | 2026-11-26 | テンプレートとして作成 | — |
