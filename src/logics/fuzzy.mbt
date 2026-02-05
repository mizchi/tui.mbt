///|
/// Fuzzy matching for filtering and searching

///|
/// Result of a fuzzy match
pub(all) struct FuzzyMatch {
  score : Int
  positions : Array[Int]
}

///|
/// Perform fuzzy matching of pattern against target string.
/// Returns None if no match, Some(FuzzyMatch) with score and matched positions.
/// Higher score = better match. Consecutive matches and word boundary matches score higher.
pub fn fuzzy_match(pattern : String, target : String) -> FuzzyMatch? {
  if pattern.length() == 0 {
    return Some(FuzzyMatch::{ score: 0, positions: [] })
  }
  if target.length() == 0 {
    return None
  }
  let pattern_lower = pattern.to_lower()
  let target_lower = target.to_lower()
  let pattern_chars = pattern_lower.to_array()
  let target_chars = target_lower.to_array()
  let best_positions : Array[Int] = []
  let best_score : Ref[Int] = Ref::new(-1)
  fn backtrack(pi : Int, ti : Int, positions : Array[Int], score : Int) {
    if pi == pattern_chars.length() {
      if best_score.val < 0 || score > best_score.val {
        best_score.val = score
        best_positions.clear()
        for p in positions {
          best_positions.push(p)
        }
      }
      return
    }
    if ti >= target_chars.length() {
      return
    }
    let remaining_pattern = pattern_chars.length() - pi
    let remaining_target = target_chars.length() - ti
    if remaining_pattern > remaining_target {
      return
    }
    for j = ti; j < target_chars.length(); j = j + 1 {
      if target_chars[j] == pattern_chars[pi] {
        let mut bonus = 0
        // Consecutive match bonus
        if positions.length() > 0 && positions[positions.length() - 1] == j - 1 {
          bonus = bonus + 4
        }
        // Word boundary bonus (after separator or case change)
        if j == 0 {
          bonus = bonus + 3
        } else {
          let prev = target.to_array()[j - 1]
          if prev == '_' ||
            prev == '-' ||
            prev == '/' ||
            prev == '.' ||
            prev == ' ' {
            bonus = bonus + 3
          }
          // Case change bonus (camelCase)
          let orig = target.to_array()[j]
          if orig.is_ascii_uppercase() && prev.is_ascii_lowercase() {
            bonus = bonus + 2
          }
        }
        // Exact case match bonus
        if target.to_array()[j] == pattern.to_array()[pi] {
          bonus = bonus + 1
        }
        let match_score = 1 + bonus
        positions.push(j)
        backtrack(pi + 1, j + 1, positions, score + match_score)
        let _ = positions.pop()

      }
    }
  }

  backtrack(0, 0, [], 0)
  if best_score.val < 0 {
    None
  } else {
    Some(FuzzyMatch::{ score: best_score.val, positions: best_positions })
  }
}

///|
/// Layout calculation for fuzzy result list.
/// Ensures total row count is always exactly max_show.
pub(all) struct FuzzyVisibleRows {
  show : Int
  has_more : Bool
  pad : Int
}

///|
/// Total rows = show + (1 if has_more) + pad == max_show always
pub fn FuzzyVisibleRows::rows(self : FuzzyVisibleRows) -> Int {
  self.show + (if self.has_more { 1 } else { 0 }) + self.pad
}

///|
/// Calculate how many items to show, whether to show "more" indicator,
/// and how many padding rows to add, so total is always max_show.
pub fn fuzzy_visible_rows(total : Int, max_show : Int) -> FuzzyVisibleRows {
  if total > max_show {
    // Reserve 1 row for "... and N more"
    { show: max_show - 1, has_more: true, pad: 0 }
  } else {
    { show: total, has_more: false, pad: max_show - total }
  }
}

///|
/// Sort items by fuzzy match score against pattern.
/// Returns array of (original_index, FuzzyMatch) sorted by score descending.
pub fn fuzzy_sort(
  pattern : String,
  items : Array[String],
) -> Array[(Int, FuzzyMatch)] {
  let results : Array[(Int, FuzzyMatch)] = []
  for i, item in items {
    match fuzzy_match(pattern, item) {
      Some(m) => results.push((i, m))
      None => ()
    }
  }
  results.sort_by(fn(a, b) { b.1.score.compare(a.1.score) })
  results
}
