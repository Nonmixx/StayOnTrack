import 'package:flutter/foundation.dart';

/// Single deadline item for the shared in-memory list.
class DeadlineItem {
  final String title;
  final String courseName;
  final DateTime? dueDate;
  final String difficulty;
  final bool isIndividual;

  DeadlineItem({
    required this.title,
    required this.courseName,
    this.dueDate,
    required this.difficulty,
    required this.isIndividual,
  });
}

/// Shared in-memory store for deadlines (Add Deadline, exams, assignments).
/// Frontend-only demo: no backend.
class DeadlineStore extends ChangeNotifier {
  final List<DeadlineItem> _items = [];

  List<DeadlineItem> get items => List.unmodifiable(_items);

  void add(DeadlineItem item) {
    _items.add(item);
    notifyListeners();
  }

  void updateAt(int index, DeadlineItem item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      notifyListeners();
    }
  }

  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }
}

/// Single shared instance for the app.
final deadlineStore = DeadlineStore();
