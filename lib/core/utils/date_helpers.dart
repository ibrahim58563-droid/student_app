import 'package:intl/intl.dart';

final class DateHelpers {
  DateHelpers._();

  static String formatArabicDate(DateTime date) {
    return DateFormat.yMMMMEEEEd('ar').format(date);
  }

  static String formatEnglishDate(DateTime date) {
    return DateFormat.yMMMMd('en').format(date);
  }
}
