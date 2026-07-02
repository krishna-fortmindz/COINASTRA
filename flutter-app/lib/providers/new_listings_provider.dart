import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/data/new_listings/new_listings_repo_impl.dart';
import '../core/remote/data/new_listings/models/new_listings_models.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class NewListingsState {
  final String filter;
  final String searchQuery;
  final AsyncValue<List<NewListing>> listings;
  final Map<String, AiListingScore> aiScores;

  const NewListingsState({
    required this.filter,
    required this.searchQuery,
    required this.listings,
    required this.aiScores,
  });

  static NewListingsState get initial => const NewListingsState(
        filter: 'All',
        searchQuery: '',
        listings: AsyncValue.loading(),
        aiScores: {},
      );

  NewListingsState copyWith({
    String? filter,
    String? searchQuery,
    AsyncValue<List<NewListing>>? listings,
    Map<String, AiListingScore>? aiScores,
  }) =>
      NewListingsState(
        filter: filter ?? this.filter,
        searchQuery: searchQuery ?? this.searchQuery,
        listings: listings ?? this.listings,
        aiScores: aiScores ?? this.aiScores,
      );

  List<NewListing> get displayList {
    final all = listings.valueOrNull ?? [];
    var result = all;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((l) =>
              l.symbol.toLowerCase().contains(q) ||
              l.name.toLowerCase().contains(q) ||
              l.category.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NewListingsNotifier extends Notifier<NewListingsState> {
  final _repo = NewListingsRepoImpl();

  @override
  NewListingsState build() {
    _fetchListings('All');
    return NewListingsState.initial;
  }

  void setFilter(String filter) {
    if (filter == state.filter) return;
    state = state.copyWith(
      filter: filter,
      listings: const AsyncValue.loading(),
      aiScores: {},
    );
    _fetchListings(filter);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refresh() {
    state = state.copyWith(listings: const AsyncValue.loading(), aiScores: {});
    return _fetchListings(state.filter);
  }

  Future<void> _fetchListings(String filter) async {
    try {
      final listings = await _repo.fetchListings(
        category: filter == 'All' ? null : filter,
      );
      state = state.copyWith(listings: AsyncValue.data(listings));
      unawaited(_prefetchAiScores(listings));
    } catch (e, st) {
      state = state.copyWith(listings: AsyncValue.error(e, st));
    }
  }

  Future<void> _prefetchAiScores(List<NewListing> listings) async {
    for (final l in listings) {
      if (l.coinId.isEmpty || state.aiScores.containsKey(l.coinId)) continue;
      try {
        final score = await _repo.fetchAiScore(l.coinId);
        // Only update if listing is still in current state (filter may have changed)
        if (state.listings.valueOrNull?.any((x) => x.coinId == l.coinId) ==
            true) {
          final updated = Map<String, AiListingScore>.from(state.aiScores);
          updated[l.coinId] = score;
          state = state.copyWith(aiScores: updated);
        }
      } catch (_) {}
    }
  }
}

final newListingsProvider =
    NotifierProvider<NewListingsNotifier, NewListingsState>(
        NewListingsNotifier.new);
