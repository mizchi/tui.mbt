# TODO

## API Redesign (React-like Declarative UI)

### Phase 1: パッケージ統一

- [x] トップレベル `@tui` からの再export
  - `@core.Color` → `@tui.Color`
  - `@c.column`, `@c.row` など → `@tui.column`, `@tui.row`
  - `@render.App` → `@tui.App`
  - ※ `@signals.signal` は外部パッケージのため別途インポート必要
- [x] examples を `@tui` インポートに統一
  - [x] simple
  - [x] counter
  - [x] button
  - [x] form
  - [x] layout
  - [x] wizard, editor, chat, command-launcher, completion
  - [x] components

### Phase 2: Dimension/Alignment の簡素化

- [x] `ToDimension` trait を導入（Double, Int, Dimension を統一的に受け入れ）
- [x] `column`/`row` を `&ToDimension` で受け入れるように変更
- [x] examples で `dim_length()` を Double 直接渡しに変更
- [ ] `justify: String` を直接受け入れ（`"center"`, `"start"`, `"end"` など）→ 後回し
- [ ] `@c.dim_length()`, `@c.align_center()` ヘルパーを deprecated に → 後回し

### Phase 3: アプリライフサイクルの簡素化

- [x] `@tui.run()` ヘルパーを作成
  ```
  @tui.run(
    fn() { ... },  // render
    fn(event) { ... },  // on_event: returns false to quit
    mouse?=true,
  )
  ```
- [x] setup/cleanup ボイラープレートを内部化
- [ ] examples を `run()` パターンに移行
  - [x] simple
  - [x] button (Phase 5 で完了)
  - [ ] counter (async ループのため run() 不向き)
  - [ ] form (編集モード切替のため複雑)

### Phase 4: Component 構造体の整理

- [x] アクセサメソッドを追加
  - `id()`, `get_node()`, `get_styles()`, `get_texts()`
  - `get_click_handlers()`, `get_roles()`
  - `get_text(id)`, `get_role(id)`
- [x] render/app.mbt をアクセサメソッドに移行
- [ ] 内部フィールド非公開化 → 断念（MoonBit の `priv` は全パッケージから隠すため内部パッケージも使えなくなる）
- [x] 公開APIの整理 → examples は直接フィールドにアクセスしていないため実質達成

### Phase 5: イベントハンドリングの統一

- [x] 主要インタラクティブ要素に `on_click` を追加
  - button (既存)
  - input, textarea (追加)
  - switch, checkbox, radio (既存)
- [x] `run()` でマウスクリックを自動ディスパッチ
  - Component の click_handlers を自動的に呼び出し
- [x] examples を on_click パターンに移行
  - [x] button - dispatch_click 不要に、on_click 直接指定
- [x] listbox, tabs に `on_select` コールバックを追加
  - listbox: `on_select? : ((String) -> Unit)?` - 選択時にオプションIDを渡す
  - tabs: `on_select? : ((String) -> Unit)?` - タブ選択時にタブIDを渡す

---

## IME 入力で複数文字が失われる問題

### 症状
- Enter を押さずに IME で入力を開始すると、最初の一文字しか反映されない
- 例: "日本語" と入力しても "日" のみが反映される

### 調査済み
1. `TCSAFLUSH` → `TCSADRAIN` に変更済み（入力バッファ破棄を防ぐ）
2. UTF-8 継続バイトのリトライロジック追加済み
3. カーソル位置取得時の pending_input 保存ロジック追加済み

### 残りの調査ポイント
- `stop_keypress_listener()` のタイミング
- 編集モード開始時のフロー全体の見直し
- キーイベントの伝搬経路の確認
