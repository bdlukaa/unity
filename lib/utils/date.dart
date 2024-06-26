import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:intl/intl.dart';

Set<String> _loggedErrorredDates = {};

/// Convert a date string to a DateTime object, considering the timezone offset.
DateTime timezoneAwareDate(String originalDateString) {
  final originalDateTime = DateTime.parse(originalDateString);

  try {
    // Get the offset sign and factors from the date string.
    //
    // If the timezone is positive (e.g. +02:00), the offset sign is positive.
    // Otherwise (e.g. -02:00), the offset sign is negative.
    var offsetSign = 1.0;
    var offsetFactors = originalDateString.split('+');
    if (offsetFactors.isEmpty) {
      offsetFactors = originalDateString.split('-');
      if (offsetFactors.length <= 2) return originalDateTime;
      offsetSign = -1.0;
    }
    final offsetString = offsetFactors.last;
    final parts = offsetString.split(':');

    // Convert hours and minutes strings to integers
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    // Create a Duration object based on the offset sign
    final offset = Duration(
      hours: (hours * offsetSign).toInt(),
      minutes: (minutes * offsetSign).toInt(),
    );

    return originalDateTime.add(offset);
  } catch (e) {
    if (!_loggedErrorredDates.contains(originalDateString)) {
      writeLogToFile(
        'Failed to parse date string: $originalDateString',
        print: true,
      );
      _loggedErrorredDates.add(originalDateString);
    }
    return originalDateTime;
  }
}

extension DateSettingsExtension on SettingsProvider {
  /// Formats the date according to the current [dateFormat].
  ///
  /// [toLocal] defines if the date will be converted to local time. Defaults to `true`
  String formatDate(DateTime date) {
    if (kConvertTimeToLocalTimezone.value) date = date.toLocal();

    return kDateFormat.value.format(date);
  }

  String formatRawTime(String rawDate) {
    return kTimeFormat.value.format(
      kConvertTimeToLocalTimezone.value
          ? DateTime.parse(rawDate).toLocal()
          : timezoneAwareDate(rawDate),
    );
  }

  /// Formats the date according to the current [dateFormat].
  ///
  /// [toLocal] defines if the date will be converted to local time. Defaults to `true`
  String formatTime(
    DateTime time, {
    DateFormat? pattern,
    bool withSeconds = false,
    bool? toLocal,
  }) {
    if (toLocal ?? kConvertTimeToLocalTimezone()) time = time.toLocal();

    pattern ??= DateFormat(kTimeFormat.value.pattern);

    if (withSeconds) {
      pattern = pattern.add_s();
    }

    return pattern.format(time);
  }

  String formatTimeRaw(
    String rawTime, {
    DateFormat? pattern,
    Duration offset = Duration.zero,
  }) {
    return formatTime(
      timezoneAwareDate(rawTime).add(offset),
      pattern: pattern,
    );
  }

  String formatRawDateAndTime(String rawDateTime) {
    final date = formatDate(DateTime.parse(rawDateTime));
    final time = formatRawTime(rawDateTime).toUpperCase();
    return '$date $time';
  }
}
