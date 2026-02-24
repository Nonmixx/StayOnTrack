import 'package:flutter/foundation.dart';

/// Single deadline item for the shared in-memory list.
/// [id] is set when loaded from or saved to Firebase (backend).
/// [type] is 'exam' or 'assignment'; must be preserved when editing so an exam is not overwritten as assignment.
class DeadlineItem {
  final String? id;
  final String title;
  final String courseName;
  final DateTime? dueDate;
  final String difficulty;
  final bool isIndividual;
  /// 'exam' or 'assignment'; preserve when loading from API so edit flow opens correct screen.
  final String? type;

  DeadlineItem({
    this.id,
    required this.title,
    required this.courseName,
    this.dueDate,
    required this.difficulty,
    required this.isIndividual,
    this.type,
  });

  DeadlineItem copyWith({
    String? id,
    String? title,
    String? courseName,
    DateTime? dueDate,
    String? difficulty,
    bool? isIndividual,
    String? type,
  }) {
    return DeadlineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      courseName: courseName ?? this.courseName,
      dueDate: dueDate ?? this.dueDate,
      difficulty: difficulty ?? this.difficulty,
      isIndividual: isIndividual ?? this.isIndividual,
      type: type ?? this.type,
    );
  }
}

/// Shared in-memory store for deadlines (Add Deadline, exams, assignments).
/// Synced with Firebase via backend API.
class DeadlineStore extends ChangeNotifier {
  final List<DeadlineItem> _items = [];

  List<DeadlineItem> get items => List.unmodifiable(_items);

  void add(DeadlineItem item) {
    _items.add(item);
    notifyListeners();
  }

  void replaceAll(List<DeadlineItem> items) {
    _items.clear();
    _items.addAll(items);
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
