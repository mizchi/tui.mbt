///|
/// Dashboard component stories

///|
pub fn sparkline_stories() -> Array[Story] {
  [
    Story::new(
      "sparkline",
      "basic",
      fn() { @components.sparkline([1.0, 3.0, 2.0, 5.0, 4.0, 7.0, 6.0, 8.0]) },
      width=15,
      height=3,
    ),
    Story::new(
      "sparkline",
      "with_width",
      fn() { @components.sparkline([1.0, 5.0, 3.0, 8.0, 2.0], width=10) },
      width=15,
      height=3,
    ),
    Story::new(
      "sparkline",
      "constant",
      fn() { @components.sparkline([5.0, 5.0, 5.0, 5.0, 5.0]) },
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
      fn() { @components.gauge("", 0.5, bar_width=15) },
      width=25,
      height=3,
    ),
    Story::new(
      "gauge",
      "with_label",
      fn() { @components.gauge("CPU", 0.75, bar_width=12) },
      width=25,
      height=3,
    ),
    Story::new(
      "gauge",
      "high_usage",
      fn() { @components.gauge("MEM", 0.95, bar_width=12) },
      width=25,
      height=3,
    ),
    Story::new(
      "gauge",
      "thin_style",
      fn() {
        @components.gauge(
          "",
          0.6,
          bar_width=15,
          style=@components.GaugeStyle::Thin,
        )
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
      fn() { @components.stat("Total", "32.0 GiB") },
      width=20,
      height=3,
    ),
    Story::new(
      "stat",
      "with_width",
      fn() { @components.stat("Used", "13.0 GiB", label_width=8) },
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
      fn() { @components.meter("C0", 0.25, width=25) },
      width=30,
      height=3,
    ),
    Story::new(
      "meter",
      "cpu_medium",
      fn() { @components.meter("C1", 0.56, width=25) },
      width=30,
      height=3,
    ),
    Story::new(
      "meter",
      "cpu_high",
      fn() { @components.meter("C2", 0.92, width=25) },
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
          @components.TableColumn::new(
            "Pid",
            width=6,
            align=@components.ColumnAlign::Right,
          ),
          @components.TableColumn::new("Name", width=10),
          @components.TableColumn::new(
            "CPU%",
            width=5,
            align=@components.ColumnAlign::Right,
          ),
        ]
        let data = [["1234", "process1", "12.3"], ["5678", "process2", "5.1"]]
        @components.table(cols, data)
      },
      width=30,
      height=4,
    ),
    Story::new(
      "table",
      "selected",
      fn() {
        let cols = [
          @components.TableColumn::new(
            "Pid",
            width=6,
            align=@components.ColumnAlign::Right,
          ),
          @components.TableColumn::new("Name", width=10),
          @components.TableColumn::new(
            "CPU%",
            width=5,
            align=@components.ColumnAlign::Right,
          ),
        ]
        let data = [["1234", "process1", "12.3"], ["5678", "process2", "5.1"]]
        @components.table(cols, data, selected_row=1)
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
        @components.titled_box(
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
        @components.titled_box(
          "cpu",
          [@components.stat("Total", "100%"), @components.stat("User", "45%")],
          width=20,
        )
      },
      width=25,
      height=6,
    ),
  ]
}
