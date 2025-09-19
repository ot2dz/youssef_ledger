import 'package:flutter/material.dart';

/// A provider dedicated to managing the selected date for the application.
///
/// This class encapsulates the logic for date selection, allowing other providers
/// and widgets to listen for and react to date changes without managing the
/// date state themselves.
class DateProvider with ChangeNotifier {
  DateTime _selectedDate = DateTime.now();

  /// The currently selected date.
  ///
  /// When a new date is set, it notifies all listeners.
  DateTime get selectedDate => _selectedDate;

  /// Updates the selected date and notifies listeners.
  ///
  /// This is the primary method for changing the application's active date.
  void selectDate(DateTime newDate) {
    if (isSameDay(_selectedDate, newDate)) return;
    _selectedDate = newDate;
    notifyListeners();
  }

  /// Moves the selected date to the next day.
  void nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    notifyListeners();
  }

  /// Moves the selected date to the previous day.
  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    notifyListeners();
  }

  /// Checks if two [DateTime] objects represent the same calendar day.
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
