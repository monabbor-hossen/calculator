/// Centralized date formatting utilities for history screens.
class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats a DateTime into user-friendly strings like:
  /// "Today, 3:45 PM" or "Oct 27, 2026 • 3:45 PM".
  static String formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $period';

    if (isToday) return 'Today, $timeStr';

    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year} • $timeStr';
  }

  /// Formats a DateTime into a relative string like "Just now", "5m ago",
  /// "Today, 3:45 PM", or "Oct 27, 3:45 PM".
  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && dt.day == now.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minute $period';
    } else {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${_months[dt.month - 1]} ${dt.day}, $hour:$minute $period';
    }
  }
}
