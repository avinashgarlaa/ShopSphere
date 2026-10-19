class LayoutBreakpoints {
  const LayoutBreakpoints._();

  static const compact = 600.0;
  static const expanded = 1024.0;

  static int gridColumns(double width) {
    if (width < compact) return 2;
    if (width < expanded) return 3;
    return 4;
  }
}
