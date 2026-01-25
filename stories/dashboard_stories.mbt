///|
/// Dashboard component stories - vnode version

///|
pub fn sparkline_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "sparkline",
      "basic",
      fn() { @vnode.sparkline([1.0, 3.0, 2.0, 5.0, 4.0, 7.0, 6.0, 8.0]) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "sparkline",
      "with_width",
      fn() { @vnode.sparkline([1.0, 5.0, 3.0, 8.0, 2.0], width=10) },
      width=15,
      height=3,
    ),
    VNodeStory::new(
      "sparkline",
      "constant",
      fn() { @vnode.sparkline([5.0, 5.0, 5.0, 5.0, 5.0]) },
      width=15,
      height=3,
    ),
  ]
}

///|
pub fn gauge_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "gauge",
      "50_percent",
      fn() { @vnode.gauge("", 0.5, bar_width=15) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "gauge",
      "with_label",
      fn() { @vnode.gauge("CPU", 0.75, bar_width=12) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "gauge",
      "high_usage",
      fn() { @vnode.gauge("MEM", 0.95, bar_width=12) },
      width=25,
      height=3,
    ),
    VNodeStory::new(
      "gauge",
      "thin_style",
      fn() { @vnode.gauge("", 0.6, bar_width=15) },
      width=25,
      height=3,
    ),
  ]
}

///|
pub fn stat_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "stat",
      "basic",
      fn() { @vnode.stat("Total", "32.0 GiB") },
      width=20,
      height=3,
    ),
    VNodeStory::new(
      "stat",
      "with_width",
      fn() { @vnode.stat("Used", "13.0 GiB", label_width=8) },
      width=25,
      height=3,
    ),
  ]
}

///|
pub fn meter_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "meter",
      "cpu_low",
      fn() { @vnode.meter("C0", 0.25, width=25) },
      width=30,
      height=3,
    ),
    VNodeStory::new(
      "meter",
      "cpu_medium",
      fn() { @vnode.meter("C1", 0.56, width=25) },
      width=30,
      height=3,
    ),
    VNodeStory::new(
      "meter",
      "cpu_high",
      fn() { @vnode.meter("C2", 0.92, width=25) },
      width=30,
      height=3,
    ),
  ]
}

///|
pub fn table_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "table",
      "basic",
      fn() {
        let cols = [
          @vnode.TableColumn::new("Pid", width=6, align=@vnode.ColumnAlign::Right),
          @vnode.TableColumn::new("Name", width=10),
          @vnode.TableColumn::new("CPU%", width=5, align=@vnode.ColumnAlign::Right),
        ]
        let data = [["1234", "process1", "12.3"], ["5678", "process2", "5.1"]]
        @vnode.table(cols, data)
      },
      width=30,
      height=4,
    ),
    VNodeStory::new(
      "table",
      "selected",
      fn() {
        let cols = [
          @vnode.TableColumn::new("Pid", width=6, align=@vnode.ColumnAlign::Right),
          @vnode.TableColumn::new("Name", width=10),
          @vnode.TableColumn::new("CPU%", width=5, align=@vnode.ColumnAlign::Right),
        ]
        let data = [["1234", "process1", "12.3"], ["5678", "process2", "5.1"]]
        @vnode.table(cols, data, selected_row=1)
      },
      width=30,
      height=4,
    ),
  ]
}

///|
pub fn titled_box_stories() -> Array[VNodeStory] {
  [
    VNodeStory::new(
      "titled_box",
      "basic",
      fn() {
        @vnode.column([
          @vnode.text("mem", fg="cyan", bold=true),
          @vnode.text("Content here"),
        ], border="rounded", border_color="cyan", padding=1.0, min_width=20.0)
      },
      width=25,
      height=5,
    ),
    VNodeStory::new(
      "titled_box",
      "with_stats",
      fn() {
        @vnode.column([
          @vnode.text("cpu", fg="cyan", bold=true),
          @vnode.stat("Total", "100%"),
          @vnode.stat("User", "45%"),
        ], border="rounded", border_color="cyan", padding=1.0, min_width=20.0)
      },
      width=25,
      height=6,
    ),
  ]
}
