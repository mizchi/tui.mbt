///|
/// Benchmarks for render module
/// Tests buffer operations and diff computation patterns
/// Hypothesis: Horizontal updates (row changes) might be slow,
/// vertical updates (column changes) might be faster due to row-major iteration

///|
/// Create a filled buffer for testing
fn create_test_buffer(width : Int, height : Int) -> CharBuffer {
  let buf = CharBuffer::new(width, height)
  let cell = CharCell::from_char('A')
  for row = 0; row < height; row = row + 1 {
    for col = 0; col < width; col = col + 1 {
      buf.set_cell(col, row, cell)
    }
  }
  buf
}

///|
/// Apply horizontal stripe change (change one row)
fn apply_horizontal_change(buf : CharBuffer, row : Int, char : Char) -> Unit {
  let cell = CharCell::from_char(char)
  for col = 0; col < buf.width; col = col + 1 {
    buf.set_cell(col, row, cell)
  }
}

///|
/// Apply vertical stripe change (change one column)
fn apply_vertical_change(buf : CharBuffer, col : Int, char : Char) -> Unit {
  let cell = CharCell::from_char(char)
  for row = 0; row < buf.height; row = row + 1 {
    buf.set_cell(col, row, cell)
  }
}

///|
/// Apply scattered changes (diagonal pattern)
fn apply_scattered_change(buf : CharBuffer, char : Char) -> Unit {
  let cell = CharCell::from_char(char)
  let count = if buf.width < buf.height { buf.width } else { buf.height }
  for i = 0; i < count; i = i + 1 {
    buf.set_cell(i, i, cell)
  }
}

// =============================================================================
// Buffer Operations
// =============================================================================

///|
test "bench_buffer_create_small" (b : @bench.T) {
  b.bench(name="buffer_create_40x20", fn() { b.keep(CharBuffer::new(40, 20)) })
}

///|
test "bench_buffer_create_medium" (b : @bench.T) {
  b.bench(name="buffer_create_80x40", fn() { b.keep(CharBuffer::new(80, 40)) })
}

///|
test "bench_buffer_create_large" (b : @bench.T) {
  b.bench(name="buffer_create_160x80", fn() { b.keep(CharBuffer::new(160, 80)) })
}

///|
test "bench_buffer_clone" (b : @bench.T) {
  let buf = create_test_buffer(80, 40)
  b.bench(name="buffer_clone_80x40", fn() { b.keep(buf.clone()) })
}

// =============================================================================
// Full Buffer to ANSI
// =============================================================================

///|
test "bench_buffer_to_ansi_small" (b : @bench.T) {
  let buf = create_test_buffer(40, 20)
  b.bench(name="buffer_to_ansi_40x20", fn() { b.keep(buf.to_ansi()) })
}

///|
test "bench_buffer_to_ansi_medium" (b : @bench.T) {
  let buf = create_test_buffer(80, 40)
  b.bench(name="buffer_to_ansi_80x40", fn() { b.keep(buf.to_ansi()) })
}

///|
test "bench_buffer_to_ansi_large" (b : @bench.T) {
  let buf = create_test_buffer(160, 80)
  b.bench(name="buffer_to_ansi_160x80", fn() { b.keep(buf.to_ansi()) })
}

// =============================================================================
// Diff-based ANSI - Horizontal Updates (Row Changes)
// Hypothesis: Adjacent cells in a row can be emitted sequentially without
// move_to commands (col == last_col + 1 optimization)
// =============================================================================

///|
test "bench_diff_horizontal_1row" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  apply_horizontal_change(current, 20, 'X')
  b.bench(name="diff_horizontal_1row_80x40", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
test "bench_diff_horizontal_5rows" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  for i = 0; i < 5; i = i + 1 {
    apply_horizontal_change(current, i * 8, 'X')
  }
  b.bench(name="diff_horizontal_5rows_80x40", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
test "bench_diff_horizontal_large" (b : @bench.T) {
  let prev = create_test_buffer(160, 80)
  let current = prev.clone()
  apply_horizontal_change(current, 40, 'X')
  b.bench(name="diff_horizontal_1row_160x80", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

// =============================================================================
// Diff-based ANSI - Vertical Updates (Column Changes)
// Hypothesis: Each cell requires move_to command since cells are not adjacent
// in the row-major iteration order
// =============================================================================

///|
test "bench_diff_vertical_1col" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  apply_vertical_change(current, 40, 'X')
  b.bench(name="diff_vertical_1col_80x40", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
test "bench_diff_vertical_5cols" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  for i = 0; i < 5; i = i + 1 {
    apply_vertical_change(current, i * 16, 'X')
  }
  b.bench(name="diff_vertical_5cols_80x40", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
test "bench_diff_vertical_large" (b : @bench.T) {
  let prev = create_test_buffer(160, 80)
  let current = prev.clone()
  apply_vertical_change(current, 80, 'X')
  b.bench(name="diff_vertical_1col_160x80", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

// =============================================================================
// Diff-based ANSI - Comparison Tests (Same Cell Count, Different Patterns)
// =============================================================================

///|
/// Compare horizontal vs vertical with equal cell count
test "bench_diff_compare_80cells_horizontal" (b : @bench.T) {
  // 80 cells in 1 row
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  apply_horizontal_change(current, 0, 'X')
  b.bench(name="diff_80cells_horizontal", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
test "bench_diff_compare_80cells_vertical" (b : @bench.T) {
  // 80 cells in 2 columns (40 rows each)
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  apply_vertical_change(current, 0, 'X')
  apply_vertical_change(current, 1, 'X')
  b.bench(name="diff_80cells_vertical", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

// =============================================================================
// Diff-based ANSI - Edge Cases
// =============================================================================

///|
test "bench_diff_scattered" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  apply_scattered_change(current, 'X')
  b.bench(name="diff_scattered_80x40", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
test "bench_diff_no_change" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  b.bench(name="diff_no_change_80x40", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
test "bench_diff_full_change" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = create_test_buffer(80, 40)
  // Change all cells to different character
  for row = 0; row < 40; row = row + 1 {
    apply_horizontal_change(current, row, 'Z')
  }
  b.bench(name="diff_full_change_80x40", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

// =============================================================================
// Sixel-like Scenario: Avoid updating a reserved region
// Simulates having an image region that shouldn't be touched
// =============================================================================

///|
/// Apply changes avoiding a rectangular region (simulating sixel area)
fn apply_change_avoiding_region(
  buf : CharBuffer,
  char : Char,
  avoid_x : Int,
  avoid_y : Int,
  avoid_w : Int,
  avoid_h : Int,
) -> Unit {
  let cell = CharCell::from_char(char)
  for row = 0; row < buf.height; row = row + 1 {
    for col = 0; col < buf.width; col = col + 1 {
      // Skip the reserved region
      if col >= avoid_x &&
        col < avoid_x + avoid_w &&
        row >= avoid_y &&
        row < avoid_y + avoid_h {
        continue
      }
      buf.set_cell(col, row, cell)
    }
  }
}

///|
/// Sixel scenario: Update everything except a 20x10 region
test "bench_diff_avoid_small_region" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  // Avoid a 20x10 region in center (200 cells reserved)
  apply_change_avoiding_region(current, 'X', 30, 15, 20, 10)
  b.bench(name="diff_avoid_20x10_region", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
/// Sixel scenario: Update everything except a 40x20 region (half the buffer)
test "bench_diff_avoid_large_region" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  // Avoid a 40x20 region (800 cells reserved = 25% of buffer)
  apply_change_avoiding_region(current, 'X', 20, 10, 40, 20)
  b.bench(name="diff_avoid_40x20_region", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
/// Sixel scenario: Only update border around image (common UI pattern)
test "bench_diff_border_only" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  let cell = CharCell::from_char('X')
  // Only change first and last row
  for col = 0; col < 80; col = col + 1 {
    current.set_cell(col, 0, cell)
    current.set_cell(col, 39, cell)
  }
  // Only change first and last column
  for row = 1; row < 39; row = row + 1 {
    current.set_cell(0, row, cell)
    current.set_cell(79, row, cell)
  }
  b.bench(name="diff_border_only_80x40", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}

///|
/// Compare: update only a status line (1 row at bottom)
test "bench_diff_status_line_only" (b : @bench.T) {
  let prev = create_test_buffer(80, 40)
  let current = prev.clone()
  apply_horizontal_change(current, 39, 'S')
  b.bench(name="diff_status_line_80x40", fn() {
    b.keep(current.diff_to_ansi(prev))
  })
}
