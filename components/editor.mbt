///|
/// Editor - Full-featured text editor component

///|
/// Editor state
pub(all) struct EditorState {
  buffer : TextBuffer
  undo_stack : UndoStack
  filename : String
  mode : SelectionMode
  modified : Bool
}

///|
/// Create empty editor state
pub fn EditorState::new() -> EditorState {
  EditorState::{
    buffer: TextBuffer::new(),
    undo_stack: UndoStack::new(),
    filename: "untitled",
    mode: SelectionMode::Caret,
    modified: false,
  }
}

///|
/// Create editor state from file (not yet implemented)
pub fn EditorState::from_file(path : String) -> EditorState {
  let buffer = TextBuffer::from_file(path)
  EditorState::{
    buffer,
    undo_stack: UndoStack::new(),
    filename: path,
    mode: SelectionMode::Caret,
    modified: false,
  }
}

///|
/// Line numbers gutter component
fn line_gutter(
  line_count : Int,
  current_line : Int,
  gutter_bg : @core.Color,
) -> @core.Component {
  let width = 4
  let fg = @core.Color::rgb(100, 100, 100)
  let bg = gutter_bg
  let current_fg = @core.Color::cyan()
  let current_bg = @core.Color::rgb(40, 40, 50)
  let components : Array[@core.Component] = []
  for i = 1; i <= line_count; i = i + 1 {
    let is_current = i == current_line
    let line_num = i.to_string()
    let padded = " ".repeat(width - line_num.length()) + line_num + " "
    let (actual_fg, actual_bg) = if is_current {
      (current_fg, current_bg)
    } else {
      (fg, bg)
    }
    components.push(text(padded, fg=actual_fg, bg=actual_bg))
  }
  column(
    components,
    bg~,
    height=@types.Dimension::Length(line_count.to_double()),
  )
}

///|
/// Status bar component
fn status_bar(
  state : EditorState,
  status_message : String,
  fg : @core.Color,
  bg : @core.Color,
) -> @core.Component {
  let mode_str = match state.mode {
    SelectionMode::Caret => "NORMAL"
    SelectionMode::VisualChar => "VISUAL"
    SelectionMode::VisualLine => "VISUAL LINE"
    SelectionMode::VisualBlock => "VISUAL BLOCK"
  }
  let cursor = state.buffer.cursor
  let line_info = cursor.row.to_string() + ":" + cursor.col.to_string()
  let modified = if state.modified { "[+]" } else { "" }
  let filename = state.filename + modified
  let mode_text = text(" " + mode_str + " ", fg=@core.Color::cyan(), bg~)
  let pos_text = text(" " + line_info + " ", fg~, bg~)
  let file_text = text(" " + filename + " ", fg~, bg~)
  let msg_text = text(status_message, fg~, bg~)
  row([mode_text, pos_text, file_text, msg_text], bg~)
}

///|
/// Main editor component
pub fn editor(
  state : EditorState,
  fg : @core.Color,
  bg : @core.Color,
  gutter_bg : @core.Color,
  line_fg : @core.Color,
  line_bg : @core.Color,
  min_width : Double,
  min_height : Double,
  show_status : Bool,
  status_message : String,
) -> @core.Component {
  let buffer = state.buffer
  let line_count = buffer.line_count()
  let current_line = buffer.cursor.row

  // Build line gutter
  let gutter = line_gutter(line_count, current_line, gutter_bg)

  // Build content lines
  let content_lines : Array[@core.Component] = []
  for i, line in buffer.lines {
    let line_num = i + 1
    let is_current = line_num == current_line
    let actual_bg = if is_current {
      line_bg
    } else {
      @core.Color::transparent()
    }
    let line_component = text(line + " ", fg=line_fg, bg=actual_bg)
    content_lines.push(line_component)
  }
  let content = column(
    content_lines,
    bg~,
    justify=@types.Alignment::Start,
    align=@types.Alignment::Start,
    height=@types.Dimension::Length(min_height),
  )

  // Build main editor area
  let editor_area = row(
    [gutter, content],
    width=@types.Dimension::Length(min_width),
    min_width=@types.Dimension::Length(min_width),
    height=@types.Dimension::Length(min_height),
  )

  // Build full editor with status bar
  if show_status {
    let editor_with_status = column(
      [editor_area, status_bar(state, status_message, fg, bg)],
      min_width=@types.Dimension::Length(min_width),
      height=@types.Dimension::Length(min_height + 1),
      bg~,
    )
    editor_with_status
  } else {
    let editor_no_status = column(
      [editor_area],
      min_width=@types.Dimension::Length(min_width),
      min_height=@types.Dimension::Length(min_height),
      bg~,
    )
    editor_no_status
  }
}

///|
/// Simple editor (without undo/redo)
pub fn simple_editor(
  buffer : TextBuffer,
  fg : @core.Color,
  bg : @core.Color,
  gutter_bg : @core.Color,
) -> @core.Component {
  let line_count = buffer.line_count()
  let current_line = buffer.cursor.row
  let gutter = line_gutter(line_count, current_line, gutter_bg)
  let content_lines : Array[@core.Component] = []
  for line in buffer.lines {
    content_lines.push(text(line + " ", fg~, bg~))
  }
  let content = column(content_lines, bg~, justify=@types.Alignment::Start)
  row([gutter, content], bg~)
}
