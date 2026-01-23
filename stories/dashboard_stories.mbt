///|
/// Dashboard component stories

///|
pub fn sparkline_stories() -> Array[Story] {
  [
    Story::new(
      "sparkline",
      "basic",
      fn() { @composed.sparkline([1.0, 3.0, 2.0, 5.0, 4.0, 7.0, 6.0, 8.0]) },
      width=15,
      height=3,
    ),
    Story::new(
      "sparkline",
      "with_width",
      fn() { @composed.sparkline([1.0, 5.0, 3.0, 8.0, 2.0], width=10) },
      width=15,
      height=3,
    ),
    Story::new(
      "sparkline",
      "constant",
      fn() { @composed.sparkline([5.0, 5.0, 5.0, 5.0, 5.0]) },
      width=15,
      height=3,
    ),
  ]
}

///|
pub fn gauge_stories() -> Array[Story] {
  [
    Story::new(
      "gauge",
      "50_percent",
      fn() { @composed.gauge("", 0.5, bar_width=15) },
      width=25,
      height=3,
    ),
    Story::new(
      "gauge",
      "with_label",
      fn() { @composed.gauge("CPU", 0.75, bar_width=12) },
      width=25,
      height=3,
    ),
    Story::new(
      "gauge",
      "high_usage",
      fn() { @composed.gauge("MEM", 0.95, bar_width=12) },
      width=25,
      height=3,
    ),
    Story::new(
      "gauge",
      "thin_style",
      fn() {
        @composed.gauge("", 0.6, bar_width=15, style=@composed.GaugeStyle::Thin)
      },
      width=25,
      height=3,
    ),
  ]
}

///|
pub fn stat_stories() -> Array[Story] {
  [
    Story::new(
      "stat",
      "basic",
      fn() { @composed.stat("Total", "32.0 GiB") },
      width=20,
      height=3,
    ),
    Story::new(
      "stat",
      "with_width",
      fn() { @composed.stat("Used", "13.0 GiB", label_width=8) },
      width=25,
      height=3,
    ),
  ]
}

///|
pub fn meter_stories() -> Array[Story] {
  [
    Story::new(
      "meter",
      "cpu_low",
      fn() { @composed.meter("C0", 0.25, width=25) },
      width=30,
      height=3,
    ),
    Story::new(
      "meter",
      "cpu_medium",
      fn() { @composed.meter("C1", 0.56, width=25) },
      width=30,
      height=3,
    ),
    Story::new(
      "meter",
      "cpu_high",
      fn() { @composed.meter("C2", 0.92, width=25) },
      width=30,
      height=3,
    ),
  ]
}

///|
pub fn table_stories() -> Array[Story] {
  [
    Story::new(
      "table",
      "basic",
      fn() {
        let cols = [
          @composed.TableColumn::new(
            "Pid",
            width=6,
            align=@composed.ColumnAlign::Right,
          ),
          @composed.TableColumn::new("Name", width=10),
          @composed.TableColumn::new(
            "CPU%",
            width=5,
            align=@composed.ColumnAlign::Right,
          ),
        ]
        let data = [["1234", "process1", "12.3"], ["5678", "process2", "5.1"]]
        @composed.table(cols, data)
      },
      width=30,
      height=4,
    ),
    Story::new(
      "table",
      "selected",
      fn() {
        let cols = [
          @composed.TableColumn::new(
            "Pid",
            width=6,
            align=@composed.ColumnAlign::Right,
          ),
          @composed.TableColumn::new("Name", width=10),
          @composed.TableColumn::new(
            "CPU%",
            width=5,
            align=@composed.ColumnAlign::Right,
          ),
        ]
        let data = [["1234", "process1", "12.3"], ["5678", "process2", "5.1"]]
        @composed.table(cols, data, selected_row=1)
      },
      width=30,
      height=4,
    ),
  ]
}

///|
pub fn titled_box_stories() -> Array[Story] {
  [
    Story::new(
      "titled_box",
      "basic",
      fn() {
        @composed.titled_box(
          "mem",
          [@components.text("Content here")],
          width=20,
        )
      },
      width=25,
      height=5,
    ),
    Story::new(
      "titled_box",
      "with_stats",
      fn() {
        @composed.titled_box(
          "cpu",
          [@composed.stat("Total", "100%"), @composed.stat("User", "45%")],
          width=20,
        )
      },
      width=25,
      height=6,
    ),
  ]
}
