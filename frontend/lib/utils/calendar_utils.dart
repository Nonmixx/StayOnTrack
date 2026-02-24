/// Calendar utilities for real date handling.
class CalendarUtils {
  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const List<String> monthAbbrevs = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const List<String> weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<String> weekdayNamesLong = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  /// Get month name (1-based).
  static String monthName(int month) => monthNames[month - 1];
  static String monthAbbrev(int month) => monthAbbrevs[month - 1];

  /// Get first day of month (DateTime).
  static DateTime firstOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  /// Get last day of month.
  static DateTime lastOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);

  /// Get Monday of the week containing [date]. Dart: 1=Mon, 7=Sun.
  static DateTime weekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Get Sunday of the week.
  static DateTime weekEnd(DateTime date) => weekStart(date).add(const Duration(days: 6));

  /// Build calendar grid for a month (Sunday = first column).
  /// Includes leading/trailing days from adjacent months. Each cell is a full DateTime.
  /// Use isInMonth(month, cell) to check if a cell belongs to the displayed month.
  static List<List<DateTime?>> buildMonthGrid(DateTime month) {
    final first = firstOfMonth(month);
    final last = lastOfMonth(month);
    // Sunday of week containing 1st
    final startOffset = first.weekday % 7;
    final daysFromSunday = startOffset == 0 ? 0 : startOffset;
    final gridStart = first.subtract(Duration(days: daysFromSunday));
    // Saturday of week containing last day (Sun-Sat week)
    final daysToSaturday = (6 - last.weekday + 7) % 7;
    final gridEnd = last.add(Duration(days: daysToSaturday));

    List<List<DateTime?>> grid = [];
    var current = gridStart;
    while (!current.isAfter(gridEnd)) {
      final week = <DateTime?>[];
      for (var i = 0; i < 7; i++) {
        week.add(current);
        current = current.add(const Duration(days: 1));
      }
      grid.add(week);
    }
    return grid;
  }

  /// True if [date] is in the same month as [month] (month can be any day in that month).
  static bool isInMonth(DateTime month, DateTime date) {
    return date.year == month.year && date.month == month.month;
  }

  /// True if [month] has already passed (last day of month is before today).
  static bool isPastMonth(DateTime month) {
    final last = lastOfMonth(month);
    final now = DateTime.now();
    return last.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Next N months from today (e.g. 12 for full year).
  static List<DateTime> nextMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) => DateTime(now.year, now.month + i, 1));
  }

  /// All 12 months of the current year. Past months can be dimmed; use isPastMonth() to check.
  /// When the year changes (e.g. to 2027), the planner updates to show 2027 months only.
  static List<DateTime> plannerMonths() {
    final year = DateTime.now().year;
    return List.generate(12, (i) => DateTime(year, i + 1, 1));
  }

  /// Format date as "Feb 17".
  static String formatShort(DateTime d) => '${monthAbbrev(d.month)} ${d.day}';
  /// Get weekday name for a date. Dart: 1=Mon, 7=Sun.
  static String weekdayName(DateTime d) => weekdayNamesLong[d.weekday % 7];

  /// User-facing date format (dd/MM/yyyy) for pickers and text fields.
  static String formatDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// ISO date string for API (yyyy-MM-dd). Use when sending dates to the backend.
  static String toIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
