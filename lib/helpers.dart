import 'package:flutter/cupertino.dart';

/// Checks whether the year, month and day of [d1] and [d2] equals
bool onSameDay(DateTime d1, DateTime d2) {
  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}

/// Created a new [DateTime] object with the year, month and day of [day] and minutes, seconds, milliseconds and microseconds of [d1]
DateTime setDay(DateTime d1, DateTime day) {
  return DateTime(
    day.year,
    day.month,
    day.day,
    d1.hour,
    d1.minute,
    d1.second,
    d1.millisecond,
    d1.microsecond,
  );
}

void showDialogWithCondition(BuildContext context, final bool condition, final String text,  Function action) {
  if (condition) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Icon(
          const IconData(
            0xF3BC,
            fontFamily: CupertinoIcons.iconFont,
            fontPackage: CupertinoIcons.iconFontPackage,
            matchTextDirection: true,
          ),
          color: CupertinoTheme.of(context).primaryContrastingColor,
        ),
        content: Text(text),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text(
              "OK",
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop("OK");
              action();
            },
          ),
          CupertinoDialogAction(
            child: const Text(
              "Abbrechen",
            ),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop("Abbrechen"),
          ),
        ],
      ),
    );
  } else {
    action();
  }
}
