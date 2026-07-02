import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/api_client.dart';
import '../core/end_points.dart';
import '../core/remote/data/journal/journal_models.dart';

// ── Filter model ──────────────────────────────────────────────────────────────

class JournalFilter {
  final String? direction; // 'long' | 'short' | null (all)
  final String? psychology;
  final String? pair;

  const JournalFilter({this.direction, this.psychology, this.pair});

  Map<String, String> toQueryParams() => {
        if (direction != null && direction!.isNotEmpty) 'direction': direction!,
        if (psychology != null && psychology!.isNotEmpty)
          'psychology': psychology!,
        if (pair != null && pair!.isNotEmpty) 'pair': pair!,
      };
}

final journalFilterProvider =
    StateProvider<JournalFilter>((ref) => const JournalFilter());

// ── Entries notifier ──────────────────────────────────────────────────────────

class JournalNotifier extends AsyncNotifier<List<JournalEntry>> {
  final _api = ApiClient.instance;

  @override
  Future<List<JournalEntry>> build() {
    final filter = ref.watch(journalFilterProvider);
    return _fetchEntries(filter);
  }

  Future<List<JournalEntry>> _fetchEntries(JournalFilter filter) async {
    final params = <String, dynamic>{'limit': '50', ...filter.toQueryParams()};
    final res = await _api.get<Map<String, dynamic>>(
      EndPoints.journal,
      queryParams: params,
    );
    final raw = res.data ?? {};
    final list =
        (raw['data'] ?? raw['entries'] ?? raw['items'] ?? []) as List;
    return list
        .whereType<Map>()
        .map((m) => JournalEntry.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchEntries(ref.read(journalFilterProvider)),
    );
  }

  Future<void> addEntry(Map<String, dynamic> data) async {
    await _api.post<Map<String, dynamic>>(EndPoints.journal, data: data);
    await _refresh();
    ref.invalidate(journalStatsProvider);
  }

  Future<void> updateEntry(String id, Map<String, dynamic> data) async {
    await _api.patch<Map<String, dynamic>>(
        EndPoints.journalEntry(id), data: data);
    await _refresh();
    ref.invalidate(journalStatsProvider);
  }

  Future<void> deleteEntry(String id) async {
    // Optimistic removal
    final prev = state.valueOrNull ?? [];
    state = AsyncData(prev.where((e) => e.id != id).toList());
    try {
      await _api.delete<void>(EndPoints.journalEntry(id));
      ref.invalidate(journalStatsProvider);
    } catch (_) {
      state = AsyncData(prev);
      rethrow;
    }
  }

  Future<void> refresh() => _refresh();
}

final journalProvider =
    AsyncNotifierProvider<JournalNotifier, List<JournalEntry>>(
        JournalNotifier.new);

// ── Stats provider ────────────────────────────────────────────────────────────

final journalStatsProvider =
    FutureProvider.autoDispose<JournalStats>((ref) async {
  final api = ApiClient.instance;
  final res =
      await api.get<Map<String, dynamic>>(EndPoints.journalStats);
  final raw = res.data ?? {};
  final inner = raw['data'];
  final payload = inner is Map<String, dynamic> ? inner : raw;
  return JournalStats.fromJson(payload);
});
