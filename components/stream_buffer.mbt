///|
/// StreamBuffer - cursor-safe partial rendering with a dedicated App buffer

///|
pub(all) struct StreamBuffer {
  app : Ref[@render.App]
  width : Ref[Int]
  height : Ref[Int]
}

///|
pub fn StreamBuffer::new(width : Int, height : Int) -> StreamBuffer {
  {
    app: { val: @render.App::new(width, height) },
    width: { val: width },
    height: { val: height },
  }
}

///|
pub fn StreamBuffer::resize(
  self : StreamBuffer,
  width : Int,
  height : Int,
) -> Unit {
  self.width.val = width
  self.height.val = height
  self.app.val = @render.App::new(width, height)
}

///|
pub fn StreamBuffer::size(self : StreamBuffer) -> (Int, Int) {
  (self.width.val, self.height.val)
}

///|
pub fn StreamBuffer::clear(self : StreamBuffer) -> Unit {
  self.app.val.clear_prev_buffer()
}

///|
pub fn StreamBuffer::sync(
  self : StreamBuffer,
  component : @core.Component,
) -> Unit {
  self.app.val.clear_prev_buffer()
  ignore(self.app.val.render(component))
}

///|
/// Render component at 0-indexed row/col while preserving cursor position
pub fn StreamBuffer::render(
  self : StreamBuffer,
  component : @core.Component,
  row? : Int = 0,
  col? : Int = 0,
  preserve_cursor? : Bool = true,
) -> Unit {
  let output = self.render_output(component, row~, col~, preserve_cursor~)
  @io.print_raw(output)
}

///|
pub fn StreamBuffer::render_output(
  self : StreamBuffer,
  component : @core.Component,
  row? : Int = 0,
  col? : Int = 0,
  preserve_cursor? : Bool = true,
) -> String {
  let mut output = ""
  if preserve_cursor {
    output = output + ansi_save_cursor()
  }
  // render_with_offset handles both full render (when prev_buffer is None)
  // and diff render (when prev_buffer exists)
  output = output +
    self.app.val.render_with_offset(component, row_offset=row, col_offset=col)
  if preserve_cursor {
    output = output + ansi_restore_cursor()
  }
  output
}
