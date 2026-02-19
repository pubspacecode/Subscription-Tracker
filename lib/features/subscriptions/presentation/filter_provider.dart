import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterState {
  final Set<String> selectedListNames;
  final Set<String> selectedCategories;

  FilterState({
    this.selectedListNames = const {},
    this.selectedCategories = const {},
  });

  FilterState copyWith({
    Set<String>? selectedListNames,
    Set<String>? selectedCategories,
  }) {
    return FilterState(
      selectedListNames: selectedListNames ?? this.selectedListNames,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }

  bool get hasFilters => selectedListNames.isNotEmpty || selectedCategories.isNotEmpty;
}

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() {
    return FilterState();
  }

  void toggleList(String listName) {
    final current = state.selectedListNames.toSet();
    if (current.contains(listName)) {
      current.remove(listName);
    } else {
      current.add(listName);
    }
    state = state.copyWith(selectedListNames: current);
  }

  void toggleCategory(String category) {
    final current = state.selectedCategories.toSet();
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(selectedCategories: current);
  }

  void clearAll() {
    state = FilterState();
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(FilterNotifier.new);
