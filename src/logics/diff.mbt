///|
/// Line-level text diff using Myers diff algorithm

///|
/// Diff operation for a single line
pub(all) enum DiffOp {
  Equal(String)
  Insert(String)
  Delete(String)
}

///|
pub fn DiffOp::is_equal(self : DiffOp) -> Bool {
  match self {
    Equal(_) => true
    _ => false
  }
}

///|
pub impl Show for DiffOp with output(self, logger) {
  match self {
    Equal(s) => logger.write_string("  " + s)
    Insert(s) => logger.write_string("+ " + s)
    Delete(s) => logger.write_string("- " + s)
  }
}

///|
/// Compute line-level diff between old and new text using Myers algorithm.
/// Returns an array of DiffOp indicating equal, inserted, and deleted lines.
pub fn diff_lines(
  old_lines : Array[String],
  new_lines : Array[String],
) -> Array[DiffOp] {
  let n = old_lines.length()
  let m = new_lines.length()
  if n == 0 && m == 0 {
    return []
  }
  if n == 0 {
    let result : Array[DiffOp] = []
    for line in new_lines {
      result.push(Insert(line))
    }
    return result
  }
  if m == 0 {
    let result : Array[DiffOp] = []
    for line in old_lines {
      result.push(Delete(line))
    }
    return result
  }
  // Myers diff algorithm
  let max = n + m
  // v[k + max] = x position for diagonal k
  let v : Array[Int] = Array::make(2 * max + 1, 0)
  // Store trace for backtracking
  let trace : Array[Array[Int]] = []
  let mut found = false
  for d = 0; d <= max; d = d + 1 {
    if found {
      break
    }
    let snapshot = v.copy()
    trace.push(snapshot)
    for k = -d; k <= d; k = k + 2 {
      let mut x = 0
      if k == -d || (k != d && v[k - 1 + max] < v[k + 1 + max]) {
        x = v[k + 1 + max]
      } else {
        x = v[k - 1 + max] + 1
      }
      let mut y = x - k
      while x < n && y < m && old_lines[x] == new_lines[y] {
        x = x + 1
        y = y + 1
      }
      v[k + max] = x
      if x >= n && y >= m {
        found = true
        break
      }
    }
  }
  // Backtrack to find the path
  let edits : Array[DiffOp] = []
  let mut x = n
  let mut y = m
  for d = trace.length() - 1; d >= 0; d = d - 1 {
    let prev_v = trace[d]
    let k = x - y
    let mut prev_k = k
    if k == -d || (k != d && prev_v[k - 1 + max] < prev_v[k + 1 + max]) {
      prev_k = k + 1
    } else {
      prev_k = k - 1
    }
    let prev_x = prev_v[prev_k + max]
    let prev_y = prev_x - prev_k
    // Diagonal moves (equal lines)
    while x > prev_x && y > prev_y {
      x = x - 1
      y = y - 1
      edits.push(Equal(old_lines[x]))
    }
    if d > 0 {
      if x == prev_x {
        // Insert
        y = y - 1
        edits.push(Insert(new_lines[y]))
      } else {
        // Delete
        x = x - 1
        edits.push(Delete(old_lines[x]))
      }
    }
  }
  edits.rev_in_place()
  edits
}
