/// Checks whether the year, month and day of [d1] and [d2] equals
bool onSameDay(DateTime d1, DateTime d2) {
  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}

/// Created a new [DateTime] object with the year, month and day of [day] and minutes, seconds, milliseconds and microseconds of [d1]
DateTime setDay(DateTime d1, DateTime day) {
  return DateTime(day.year, day.month, day.day, d1.hour, d1.minute, d1.second, d1.millisecond, d1.microsecond);
}
