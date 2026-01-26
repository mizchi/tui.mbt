///|
/// Accessible form components (label, fieldset, error_message, help_text)

///|
/// Label component - associates text with an input field
/// Shows required indicator (*) when required=true
pub fn label(
  text : String,
  for_id? : String = "",
  required? : Bool = false,
  id? : String = "",
) -> @vnode.TuiNode {
  let label_text = if required { text + " *" } else { text }
  let actual_id = if id == "" && for_id != "" { "label-" + for_id } else { id }
  @vnode.row(id=actual_id, [
    @vnode.text(label_text, fg="cyan"),
    if required {
      @vnode.text("", fg="red") // required indicator already in label_text
    } else {
      @vnode.text("")
    },
  ])
}

///|
/// Fieldset component - groups related form fields with a legend
/// Renders as a bordered container with the legend in the top border
pub fn fieldset(
  legend~ : String,
  id? : String = "",
  children? : Array[@vnode.TuiNode] = [],
) -> @vnode.TuiNode {
  let all_children : Array[@vnode.TuiNode] = [
    @vnode.text(legend, fg="white", bold=true),
    @vnode.vspace(0.5),
  ]
  for child in children {
    all_children.push(child)
  }
  @vnode.column(
    id~,
    border="rounded",
    border_color="rgb(80,80,100)",
    padding=1.0,
    gap=0.5,
    all_children,
  )
}

///|
/// Error message component - displays validation errors
/// Uses red color and error icon for visibility
pub fn error_message(
  text : String,
  visible? : Bool = true,
  id? : String = "",
) -> @vnode.TuiNode {
  if not(visible) || text == "" {
    @vnode.text("") // empty node when not visible
  } else {
    @vnode.row(id~, gap=0.5, [
      @vnode.text("!", fg="red", bold=true),
      @vnode.text(text, fg="red"),
    ])
  }
}

///|
/// Help text component - displays hint or description for a field
/// Uses dimmed color to distinguish from main content
pub fn help_text(text : String, id? : String = "") -> @vnode.TuiNode {
  if text == "" {
    @vnode.text("")
  } else {
    @vnode.row(id~, [@vnode.text(text, fg="rgb(128,128,128)")])
  }
}

///|
/// Form field wrapper - combines label, input, help_text, and error_message
/// Provides consistent layout for form fields
pub fn form_field(
  label_text~ : String,
  for_id? : String = "",
  required? : Bool = false,
  help? : String = "",
  error? : String = "",
  id? : String = "",
  child~ : @vnode.TuiNode,
) -> @vnode.TuiNode {
  let field_id = if id == "" && for_id != "" { "field-" + for_id } else { id }
  @vnode.column(id=field_id, gap=0.5, [
    label(label_text, for_id~, required~),
    child,
    if help != "" && error == "" {
      help_text(help)
    } else {
      @vnode.text("")
    },
    error_message(error, visible=error != ""),
  ])
}
