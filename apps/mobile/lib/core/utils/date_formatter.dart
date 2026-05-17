import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d').format(date.toLocal());
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date.toLocal());
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal());
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date.toLocal());
  }

  static String formatRelative(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localDate);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes <= 0) return 'Just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return formatShortDate(localDate);
  }

  static String getDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date.toLocal());
  }
}
