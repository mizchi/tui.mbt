///|
/// Breadcrumb navigation component

///|
/// Breadcrumb component showing navigation path
pub fn breadcrumb(
  items : Array[String],
  separator? : String = " > ",
  id? : String = "",
  active_fg? : String = "cyan",
  inactive_fg? : String = "rgb(150,150,150)",
) -> @vnode.TuiNode {
  let nodes : Array[@vnode.TuiNode] = []
  for i, item in items {
    if i > 0 {
      nodes.push(@vnode.text(separator, fg=inactive_fg))
    }
    let is_last = i == items.length() - 1
    let fg = if is_last { active_fg } else { inactive_fg }
    nodes.push(@vnode.text(item, fg~, bold=is_last))
  }
  @vnode.row(id~, nodes)
}

///|
/// Condensed path breadcrumb - shortens middle segments when path is long
pub fn condensed_breadcrumb(
  path : String,
  max_segments? : Int = 5,
  separator? : String = "/",
  id? : String = "",
) -> @vnode.TuiNode {
  let parts_raw = path.split(separator).collect()
  let parts : Array[String] = parts_raw.map(fn(sv) { sv.to_string() })
  let items : Array[String] = if parts.length() <= max_segments {
    parts
  } else {
    let result : Array[String] = []
    result.push(parts[0])
    result.push("...")
    // Show last (max_segments - 2) segments
    let start = parts.length() - (max_segments - 2)
    for i = start; i < parts.length(); i = i + 1 {
      result.push(parts[i])
    }
    result
  }
  breadcrumb(items, separator=" " + separator + " ", id~)
}
