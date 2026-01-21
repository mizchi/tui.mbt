///|
/// Tests for Headless Runner (Playwright-style API)

// ============================================
// Basic App Tests
// ============================================

///|
test "headless_app: create app" {
  let app = @components.HeadlessApp::new(width=80, height=24)
  inspect(app.width, content="80")
  inspect(app.height, content="24")
}

///|
test "headless_app: render component" {
  let app = @components.HeadlessApp::new()
  let component = @c.text("Hello", id="test")
  let rendered = app.render(component)
  match rendered.buffer {
    Some(buf) => inspect(buf.width, content="80")
    None => assert_true(false)
  }
}

///|
test "headless_app: get content" {
  let app = @components.HeadlessApp::new()
  let component = @c.text("Hello World", id="test")
  let rendered = app.render(component)
  let content = rendered.content()
  inspect(content.contains("Hello World"), content="true")
}

// ============================================
// Locator Tests
// ============================================

///|
test "locator: find by ID" {
  let app = @components.HeadlessApp::new()
  let component = @c.text("Hello", id="test-id")
  let rendered = app.render(component)
  let locator = rendered.locator("test-id")
  inspect(locator.exists(), content="true")
}

///|
test "locator: get element text" {
  let app = @components.HeadlessApp::new()
  let component = @c.text("Hello World", id="test-id")
  let rendered = app.render(component)
  let locator = rendered.locator("test-id")
  let text = locator.text()
  inspect(text.contains("Hello"), content="true")
}

///|
test "locator: non-existent element" {
  let app = @components.HeadlessApp::new()
  let component = @c.text("Hello", id="test-id")
  let rendered = app.render(component)
  let locator = rendered.locator("non-existent")
  inspect(locator.exists(), content="false")
}

// ============================================
// Page Tests
// ============================================

///|
test "page: create from app" {
  let app = @components.HeadlessApp::new()
  let page = @components.Page::new(app)
  let content = page.content()
  inspect(content, content="")
}

///|
test "page: get content after render" {
  let app = @components.HeadlessApp::new()
  let component = @c.text("Test Content", id="test")
  let rendered = app.render(component)
  let page = @components.Page::new(rendered)
  let content = page.content()
  inspect(content.contains("Test"), content="true")
}

// ============================================
// Assertions Tests
// ============================================

///|
test "assertions: is_visible" {
  let app = @components.HeadlessApp::new()
  let component = @c.text("Hello", id="visible")
  let rendered = app.render(component)
  let locator = rendered.locator("visible")
  let assertions = @components.Assertions::new(locator)
  inspect(assertions.is_visible(), content="true")
}

///|
test "assertions: has_text" {
  let app = @components.HeadlessApp::new()
  let component = @c.text("Exact Text", id="test-id")
  let rendered = app.render(component)
  let locator = rendered.locator("test-id")
  let assertions = locator.assertions()
  inspect(assertions.has_text("Exact Text"), content="true")
  inspect(assertions.has_text("Wrong Text"), content="false")
}

///|
test "assertions: contains_text" {
  let app = @components.HeadlessApp::new()
  let component = @c.text("Hello World", id="test-id")
  let rendered = app.render(component)
  let locator = rendered.locator("test-id")
  let assertions = locator.assertions()
  inspect(assertions.contains_text("Hello"), content="true")
  inspect(assertions.contains_text("World"), content="true")
  inspect(assertions.contains_text("Bye"), content="false")
}

// ============================================
// Snapshot Tests
// ============================================

///|
test "snapshot: simple text" {
  let app = @components.HeadlessApp::new(width=40, height=10)
  let component = @c.text("Snapshot Test", id="test")
  @components.snapshot(app.render(component), "simple_text")
}

///|
test "snapshot: complex layout" {
  let app = @components.HeadlessApp::new(width=60, height=15)
  let component = @c.column(
    [
      @c.text("Header", fg=@core.Color::cyan()),
      @c.vspace(1.0),
      @c.text("Content"),
      @c.vspace(1.0),
      @c.text("Footer", fg=@core.Color::gray()),
    ],
    padding=1.0,
    border=Some(@core.BorderChars::single()),
  )
  @components.snapshot(app.render(component), "complex_layout")
}

// ============================================
// Integration Tests
// ============================================

///|
test "integration: editor rendering" {
  let app = @components.HeadlessApp::new(width=80, height=24)
  let editor_state = @components.EditorState::new()
  let buffer = editor_state.buffer.insert_string("Line 1\nLine 2\nLine 3")
  let editor_state_with_buffer = @components.EditorState::{ buffer, ..editor_state }
  let component = @components.simple_editor(buffer, id="editor")
  let rendered = app.render(component)
  let page = @components.Page::new(rendered)
  let content = page.content()
  inspect(content.contains("Line 1"), content="true")
  inspect(content.contains("Line 2"), content="true")
  inspect(content.contains("Line 3"), content="true")
}
