import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flower_memory.dart';
import '../services/storage_service.dart';

class MemoryNotifier extends Notifier<List<FlowerMemory>> {
  bool _isLoaded = false;

  @override
  List<FlowerMemory> build() {
    if (!_isLoaded) {
      _loadFromStorage();
    }
    return [];
  }

  Future<void> _loadFromStorage() async {
    final saved = await StorageService.loadMemories();
    _isLoaded = true;
    state = saved;
  }

  Future<void> addMemory(FlowerMemory memory) async {
    await StorageService.saveMemory(memory);
    state = [memory, ...state];
  }

  Future<void> removeMemory(String id) async {
    await StorageService.deleteMemory(id);
    state = state.where((m) => m.id != id).toList();
  }
}

final memoryProvider = NotifierProvider<MemoryNotifier, List<FlowerMemory>>(
  MemoryNotifier.new,
);

class SeasonFilterNotifier extends Notifier<String> {
  @override
  String build() => '전체';

  void setFilter(String season) {
    state = season;
  }
}

final seasonFilterProvider = NotifierProvider<SeasonFilterNotifier, String>(
  SeasonFilterNotifier.new,
);

final filteredMemoriesProvider = Provider<List<FlowerMemory>>((ref) {
  final memories = ref.watch(memoryProvider);
  final filter = ref.watch(seasonFilterProvider);

  if (filter == '전체') return memories;
  return memories.where((m) => m.season == filter).toList();
});
