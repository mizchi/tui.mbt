# vnode 完全移行計画

## ステータス: 完了

全フェーズが完了し、v0.3.0 としてリリース準備完了。

## 新パッケージ構成

### headless - ヘッドレスコンポーネント
ロジック・状態管理のみ（スタイルなし）。APG パターンに準拠。

```moonbit
// 状態型
@headless.ButtonState::{Default, Focused, Pressed, Disabled}
@headless.InputState::{Idle, Focused, Editing, Disabled}
@headless.ToggleState
@headless.SelectionState
@headless.ModalState
@headless.AccordionState
@headless.FocusNav
```

### components - スタイル付きコンポーネント
headless を使った既製のスタイル付き UI。

```moonbit
// ボタン
@components.button(label, state?, min_width?)
@components.icon_button(icon, state?)
@components.text_button(label, state?)

// トグル
@components.checkbox(label, checked, focused?, disabled?)
@components.radio(label, selected, disabled?)
@components.switch(on, label, disabled?)

// 選択
@components.tab(label, selected)
@components.tab_bar(tabs, selected_id)
@components.listbox(items, selected_id)
@components.listbox_item(label, selected)
@components.combobox_trigger(label, open)
@components.combobox_item(label, selected)

// モーダル
@components.modal(title, content, width?)
@components.modal_backdrop()
@components.alert_dialog(message, title?, button_label?)
@components.confirm_dialog(message, title?, confirm_label?, cancel_label?)
@components.card(content, title?)

// メニュー
@components.menubar_item(label, open)
@components.menu_item(label, selected, disabled?)
@components.menu_divider()

// アコーディオン
@components.accordion_section(title, content, expanded)

// フィードバック
@components.progress_bar(ratio, width?, show_percent?)
@components.spinner(tick, label?)
@components.divider(char?, fg?)
```

### vnode - コアプリミティブ
低レベルのレイアウトとテキストノード。

```moonbit
@vnode.column(children, gap?, padding?, border?, ...)
@vnode.row(children, gap?, padding?, border?, ...)
@vnode.text(content, fg?, bold?)
@vnode.fragment(children)
@vnode.spacer()
@vnode.hspace(width)
@vnode.vspace(height)
```

## 使用例

### headless + カスタムスタイル
```moonbit
// 独自スタイルのボタン
fn my_button(label : String, state : @headless.ButtonState) -> @vnode.TuiNode {
  let bg = match state {
    Default => "blue"
    Focused => "lightblue"
    _ => "gray"
  }
  @vnode.row([@vnode.text(label)], bg~, padding=1.0)
}
```

### components - すぐ使える
```moonbit
fn view() -> @vnode.TuiNode {
  @vnode.column([
    @components.button("Submit"),
    @components.checkbox("I agree", true),
    @components.progress_bar(0.7),
  ])
}
```

## 移行完了フェーズ

- ✅ Phase 1: vnode に高レベルコンポーネントを追加
- ✅ Phase 2: examples を vnode 版に完全移行
- ✅ Phase 3: stories を vnode 版に移行
- ✅ Phase 4: @components, @composed を削除
- ✅ Phase 5: トップレベル API の整理
- ✅ Phase 6: headless + components 分離
