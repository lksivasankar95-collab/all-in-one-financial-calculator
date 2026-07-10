import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/hive_database.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  void _load() {
    state = HiveDatabase.getFavorites().toSet();
  }

  Future<void> toggle(String calculatorId) async {
    if (state.contains(calculatorId)) {
      await HiveDatabase.removeFavorite(calculatorId);
      state = {...state}..remove(calculatorId);
    } else {
      await HiveDatabase.addFavorite(calculatorId);
      state = {...state, calculatorId};
    }
  }

  bool isFavorite(String calculatorId) => state.contains(calculatorId);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);
