///|
/// Tests for Accordion component

// ============================================
// Snapshot Tests
// ============================================

///|
test "accordion: collapsed state" {
  let items = [
    @components.AccordionItem::{
      id: "sec1",
      title: "Section 1",
      content: @core.text("Content 1"),
      expanded: false,
    },
    @components.AccordionItem::{
      id: "sec2",
      title: "Section 2",
      content: @core.text("Content 2"),
      expanded: false,
    },
  ]
  let comp = accordion(items)
  let output = @render.render_once(40, 6, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m▶ Section 1                             \u{1b}[2;1H                                        \u{1b}[3;1H                                        \u{1b}[4;1H▶ Section 2                             \u{1b}[5;1H                                        \u{1b}[6;1H                                        \u{1b}[0m",
  )
}

///|
test "accordion: expanded state" {
  let items = [
    @components.AccordionItem::{
      id: "sec1",
      title: "Section 1",
      content: @core.text("Details here"),
      expanded: true,
    },
    @components.AccordionItem::{
      id: "sec2",
      title: "Section 2",
      content: @core.text("More info"),
      expanded: false,
    },
  ]
  let comp = accordion(items)
  let output = @render.render_once(40, 8, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[1m\u{1b}[38;5;51m▼ Section 1\u{1b}[0m\u{1b}[38;5;231m                             \u{1b}[2;1H                                        \u{1b}[3;1H                                        \u{1b}[4;1H\u{1b}[38;5;60m┌──────────────┐\u{1b}[38;5;231m                        \u{1b}[5;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m              \u{1b}[38;5;60m│\u{1b}[38;5;231m                        \u{1b}[6;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m Details here \u{1b}[38;5;60m│\u{1b}[38;5;231m                        \u{1b}[7;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m              \u{1b}[38;5;60m│\u{1b}[38;5;231m                        \u{1b}[8;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m              \u{1b}[38;5;60m│\u{1b}[38;5;231m                        \u{1b}[0m",
  )
}

///|
test "accordion: multiple expanded" {
  let items = [
    @components.AccordionItem::{
      id: "a",
      title: "A",
      content: @core.text("A content"),
      expanded: true,
    },
    @components.AccordionItem::{
      id: "b",
      title: "B",
      content: @core.text("B content"),
      expanded: true,
    },
  ]
  let comp = accordion(items)
  let output = @render.render_once(30, 14, comp)
  inspect(
    output,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[1m\u{1b}[38;5;51m▼ A\u{1b}[0m\u{1b}[38;5;231m                           \u{1b}[2;1H                              \u{1b}[3;1H                              \u{1b}[4;1H                              \u{1b}[5;1H\u{1b}[38;5;60m┌───────────┐\u{1b}[38;5;231m                 \u{1b}[6;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m           \u{1b}[38;5;60m│\u{1b}[38;5;231m                 \u{1b}[7;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m A content \u{1b}[38;5;60m│\u{1b}[38;5;231m                 \u{1b}[8;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m           \u{1b}[38;5;60m│\u{1b}[38;5;231m                 \u{1b}[9;1H\u{1b}[38;5;60m│\u{1b}[38;5;231m           \u{1b}[38;5;60m│\u{1b}[38;5;231m                 \u{1b}[10;1H\u{1b}[38;5;60m└───────────┘\u{1b}[38;5;231m                 \u{1b}[11;1H\u{1b}[1m\u{1b}[38;5;51m▼ B\u{1b}[0m\u{1b}[38;5;231m                           \u{1b}[12;1H                              \u{1b}[13;1H                              \u{1b}[14;1H                              \u{1b}[0m",
  )
}

///|
test "accordion_header: standalone header" {
  let collapsed = accordion_header("Collapsed", false)
  let expanded = accordion_header("Expanded", true)
  let output_c = @render.render_once(20, 1, collapsed)
  let output_e = @render.render_once(20, 1, expanded)
  inspect(
    output_c,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[38;5;231m▶ Collapsed         \u{1b}[0m",
  )
  inspect(
    output_e,
    content="\u{1b}[2J\u{1b}[1;1H\u{1b}[1m\u{1b}[38;5;51m▼ Expanded\u{1b}[0m\u{1b}[38;5;231m          \u{1b}[0m",
  )
}

// ============================================
// Accessibility Tests
// ============================================

///|
test "a11y: accordion - each section has unique ID" {
  let items = [
    @components.AccordionItem::{
      id: "faq1",
      title: "FAQ 1",
      content: @core.text("Answer 1"),
      expanded: false,
    },
    @components.AccordionItem::{
      id: "faq2",
      title: "FAQ 2",
      content: @core.text("Answer 2"),
      expanded: true,
    },
  ]
  let comp = accordion(items)
  let ids : Array[String] = []
  for child in comp.node.children {
    ids.push(child.id)
  }
  inspect(
    ids,
    content=(
      #|["faq1", "faq2"]
    ),
  )
}

///|
test "a11y: accordion - expand icon indicates state" {
  let collapsed = accordion_header("Test", false)
  let expanded = accordion_header("Test", true)
  let out_c = @render.render_once(20, 1, collapsed)
  let out_e = @render.render_once(20, 1, expanded)
  inspect(out_c.contains("▶"), content="true")
  inspect(out_e.contains("▼"), content="true")
}

///|
test "a11y: accordion - header has focusable ID" {
  let header = accordion_header("Section", false, id="section-header")
  inspect(header.node.id, content="section-header")
}

///|
test "a11y: accordion - expanded content is visible" {
  let items = [
    @components.AccordionItem::{
      id: "exp",
      title: "Expanded",
      content: @core.text("VISIBLE_CONTENT"),
      expanded: true,
    },
  ]
  let comp = accordion(items)
  let output = @render.render_once(30, 8, comp)
  inspect(output.contains("VISIBLE_CONTENT"), content="true")
}

///|
test "a11y: accordion - collapsed content is hidden" {
  let items = [
    @components.AccordionItem::{
      id: "col",
      title: "Collapsed",
      content: @core.text("HIDDEN_CONTENT"),
      expanded: false,
    },
  ]
  let comp = accordion(items)
  let output = @render.render_once(30, 4, comp)
  // Content should not be visible when collapsed
  inspect(output.contains("HIDDEN_CONTENT"), content="false")
}

///|
test "a11y: accordion - header and content linked by ID" {
  let items = [
    @components.AccordionItem::{
      id: "section",
      title: "Title",
      content: @core.text("Body"),
      expanded: true,
    },
  ]
  let comp = accordion(items)
  // Find section container
  let section = comp.node.children[0]
  inspect(section.id, content="section")
  // First child should be header with ID suffix
  let header = section.children[0]
  inspect(header.id, content="section-header")
}

///|
test "a11y: accordion - multiple sections independently expandable" {
  let items = [
    @components.AccordionItem::{
      id: "s1",
      title: "Section 1",
      content: @core.text("C1"),
      expanded: true,
    },
    @components.AccordionItem::{
      id: "s2",
      title: "Section 2",
      content: @core.text("C2"),
      expanded: false,
    },
    @components.AccordionItem::{
      id: "s3",
      title: "Section 3",
      content: @core.text("C3"),
      expanded: true,
    },
  ]
  let comp = accordion(items)
  let output = @render.render_once(30, 15, comp)
  // S1 and S3 content visible, S2 hidden
  inspect(output.contains("C1"), content="true")
  inspect(output.contains("C2"), content="false")
  inspect(output.contains("C3"), content="false")
}
