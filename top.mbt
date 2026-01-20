///|
/// Re-exports for convenient access to commonly used types

// === Core types ===
pub using @core {
  type Component,
  type Color,
  type BorderChars,
  type RenderStyleMap,
  type TextContentMap,
}

// === Render types ===

///|
pub using @render {type App, type CharBuffer, type CharCell, type TextStyle}

// === Event types ===

///|
pub using @events {
  type InputEvent,
  type KeyEvent,
  type KeyModifier,
  type SpecialKey,
  type MouseEvent,
  type MouseButton,
  type MouseEventType,
  type FocusManager,
  type FocusState,
  type InputMode,
  type HitTestResult,
  type EventHandlers,
}

// === I/O types ===

///|
pub using @io {type InputResult}

// === Component types ===

///|
pub using @components {
  type ButtonState,
  type InputState,
  type TextareaState,
  type ScrollState,
  type ProgressStyle,
  type StreamingState,
  type ItemScroller,
  type ActionMenu,
  type ModalState,
  type EditConfig,
}
