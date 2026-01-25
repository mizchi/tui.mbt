# vnode 完全移行計画

## 現状

| パッケージ | 状態 | 依存元 |
|-----------|------|--------|
| `@core` | 維持（低レベル） | render, vnode, io, input, events 等 |
| `@components` | 移行対象 | top, testing, stories, examples/form, examples/editor, composed |
| `@composed` | 削除予定 | stories |
| `@vnode` | 移行先 | examples/* |
| `@stories` | 移行対象 | examples/snapshot, lint, snapshot-ansi |

## 移行フェーズ

### Phase 1: vnode に高レベルコンポーネントを追加

**ファイル構成:**
- `vnode/components/button.mbt` - button, icon_button
- `vnode/components/checkbox.mbt` - checkbox, radio, switch
- `vnode/components/accordion.mbt` - accordion
- `vnode/components/tabs.mbt` - tabs
- `vnode/components/listbox.mbt` - listbox
- `vnode/components/combobox.mbt` - combobox, autocomplete
- `vnode/components/modal.mbt` - modal, dialog
- `vnode/components/menu.mbt` - menubar, context_menu
- `vnode/components/progress.mbt` - progress_bar, spinner
- `vnode/components/tooltip.mbt` - tooltip

**優先度:**
1. button, checkbox (基本)
2. modal, dialog (よく使う)
3. tabs, accordion (レイアウト)
4. listbox, combobox (選択)
5. menubar, context_menu (ナビゲーション)
6. progress, spinner, tooltip (フィードバック)

### Phase 2: examples を vnode 版に完全移行

- [ ] `examples/form` - @components.input → @vnode.input
- [ ] `examples/editor` - @components 依存を削除

### Phase 3: stories を vnode 版に移行

1. `stories/story.mbt` の Story 型を vnode 版に変更
2. 各 `*_stories.mbt` を vnode で書き直し
3. `examples/snapshot*` を vnode 版に対応

### Phase 4: 非推奨化と削除

- [ ] `@components` を deprecated としてマーク
- [ ] `@composed` を削除
- [ ] `testing` の @components 依存を削除

### Phase 5: トップレベル API の整理

- [ ] `top.mbt` の再エクスポートを vnode 版に変更
- [ ] `moon.mod.json` のバージョンを 1.0.0 に

## 削除予定ファイル

```
composed/          # 全削除
components/        # 全削除（Phase 4 完了後）
```

## 維持するパッケージ

```
core/              # 低レベル（Color, BorderChars, Component 型）
render/            # レンダリング（CharBuffer, App）
vnode/             # 新 API（全コンポーネント）
input/             # キーボード入力
io/                # プラットフォーム I/O
events/            # イベント型
completion/        # 補完エンジン
ai/                # Claude API
testing/           # テストユーティリティ
stories/           # vnode 版スナップショット
```

## 見積もり

| Phase | 規模 | 備考 |
|-------|------|------|
| Phase 1 | 大 | 10+ コンポーネント新規作成 |
| Phase 2 | 小 | 2 examples |
| Phase 3 | 中 | 157 stories 書き直し |
| Phase 4 | 小 | 削除のみ |
| Phase 5 | 小 | 再エクスポート整理 |
