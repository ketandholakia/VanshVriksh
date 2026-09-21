import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int fanChartAncestorGenerationsDefault = 6;
const List<int> fanChartAncestorGenerationsOptions = [4, 5, 6, 7, 8];

const _fanChartAncestorGenerationsKey = 'fan_chart_ancestor_generations';

final fanChartAncestorGenerationsProvider =
    AsyncNotifierProvider<FanChartAncestorGenerationsController, int>(
      FanChartAncestorGenerationsController.new,
    );

class FanChartAncestorGenerationsController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_fanChartAncestorGenerationsKey) ??
        fanChartAncestorGenerationsDefault;
  }

  Future<void> setDepth(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fanChartAncestorGenerationsKey, value);
    state = AsyncData(value);
  }
}
