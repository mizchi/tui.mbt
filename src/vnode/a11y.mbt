///|
/// Accessibility tree extraction for vnode layouts

///|
pub struct A11yRect {
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Show)

///|
pub struct A11yNode {
  id : String
  role : @core.Role
  name : String
  rect : A11yRect
  children : Array[A11yNode]
} derive(Show)

///|
priv struct A11yBuildResult {
  nodes : Array[A11yNode]
  text_for_parent : String
}

///|
fn normalize_text(s : String) -> String {
  s.trim(chars=" \n\t").to_string()
}

///|
fn merge_text(a : String, b : String) -> String {
  if a == "" {
    b
  } else if b == "" {
    a
  } else {
    a + " " + b
  }
}

///|
fn infer_role(ctx : RenderContext, id : String) -> @core.Role? {
  match ctx.roles.get(id) {
    Some(role) => Some(role)
    None =>
      match ctx.handlers.get(id) {
        Some(_) => Some(@core.Role::Button)
        None => None
      }
  }
}

///|
fn build_a11y(
  layout : @types.Layout,
  ctx : RenderContext,
  offset_x : Double,
  offset_y : Double,
) -> A11yBuildResult {
  let abs_x = offset_x + layout.x
  let abs_y = offset_y + layout.y
  let rect = @core.normalize_grid_rect(
    abs_x,
    abs_y,
    layout.width,
    layout.height,
  )
  let x = rect.x
  let y = rect.y
  let w = rect.width
  let h = rect.height
  let own_text = match ctx.texts.get(layout.id) {
    Some(text) => normalize_text(text)
    None => ""
  }
  let mut name_text = own_text
  let mut text_for_parent = own_text
  let child_nodes : Array[A11yNode] = []
  for child in layout.children {
    let result = build_a11y(child, ctx, abs_x, abs_y)
    for n in result.nodes {
      child_nodes.push(n)
    }
    name_text = merge_text(name_text, result.text_for_parent)
    text_for_parent = merge_text(text_for_parent, result.text_for_parent)
  }
  match infer_role(ctx, layout.id) {
    Some(role) => {
      let node : A11yNode = {
        id: layout.id,
        role,
        name: normalize_text(name_text),
        rect: { x, y, width: w, height: h },
        children: child_nodes,
      }
      { nodes: [node], text_for_parent: "" }
    }
    None => { nodes: child_nodes, text_for_parent }
  }
}

///|
pub fn build_a11y_tree(
  layout : @types.Layout,
  ctx : RenderContext,
) -> Array[A11yNode] {
  let result = build_a11y(layout, ctx, 0.0, 0.0)
  result.nodes
}

///|
fn dump_a11y_node(node : A11yNode, depth : Int) -> String {
  let indent = "  ".repeat(depth)
  let role = node.role.to_string()
  let name = if node.name == "" { "" } else { " name=\"" + node.name + "\"" }
  let rect = " rect=(" +
    node.rect.x.to_string() +
    "," +
    node.rect.y.to_string() +
    ") " +
    node.rect.width.to_string() +
    "x" +
    node.rect.height.to_string()
  let mut result = indent + role + " id=" + node.id + name + rect + "\n"
  for child in node.children {
    result = result + dump_a11y_node(child, depth + 1)
  }
  result
}

///|
pub fn dump_a11y_tree(nodes : Array[A11yNode]) -> String {
  let mut result = ""
  for node in nodes {
    result = result + dump_a11y_node(node, 0)
  }
  result
}
