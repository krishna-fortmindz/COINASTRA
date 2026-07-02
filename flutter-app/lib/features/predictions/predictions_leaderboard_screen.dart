import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/remote/data/predictions/models/predictions_models.dart';
import '../../providers/predictions_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';

class PredictionsLeaderboardScreen extends ConsumerStatefulWidget {
  const PredictionsLeaderboardScreen({super.key});

  @override
  ConsumerState<PredictionsLeaderboardScreen> createState() =>
      _PredictionsLeaderboardScreenState();
}

class _PredictionsLeaderboardScreenState
    extends ConsumerState<PredictionsLeaderboardScreen> {
  String _timeframe = '30d';
  static const _timeframes = ['7d', '30d', '90d', 'all'];

  void _showMakePrediction() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _MakePredictionSheet(),
    );
  }

  void _showAuthRequired() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientGreen,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.black, size: 24),
            ),
            const SizedBox(height: 16),
            const Text('Sign In Required',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 8),
            const Text(
                'Create a free account to make predictions and track your accuracy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Sign In / Register',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider(_timeframe));
    final userState = ref.watch(userPredictionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            loggedIn ? _showMakePrediction() : _showAuthRequired(),
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Make Prediction',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onRefresh: () {
              ref.invalidate(leaderboardProvider(_timeframe));
              ref.read(userPredictionsProvider.notifier).refresh();
            }),
            const SizedBox(height: 20),
            // User vs AI card
            _UserVsAiCard(vsAiAsync: userState.vsAi),
            const SizedBox(height: 20),
            // My predictions history
            _MyPredictionsCard(mineAsync: userState.mine),
            const SizedBox(height: 20),
            // Leaderboard section with timeframe filter
            Row(
              children: [
                const Text(
                  'Accuracy Rankings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                ..._timeframes.map((t) => GestureDetector(
                      onTap: () => setState(() => _timeframe = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _timeframe == t
                              ? AppColors.brandGreen.withAlpha(20)
                              : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _timeframe == t
                                ? AppColors.brandGreen
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _timeframe == t
                                ? AppColors.brandGreen
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 12),
            leaderboardAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child:
                      CircularProgressIndicator(color: AppColors.brandGreen),
                ),
              ),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (entries) => _LeaderboardBody(entries: entries),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Accuracy Leaderboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Which coins the AI predicts most accurately',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _UserVsAiCard extends StatelessWidget {
  final AsyncValue<UserVsAi> vsAiAsync;
  const _UserVsAiCard({required this.vsAiAsync});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.brandPurple.withAlpha(40),
      child: vsAiAsync.when(
        loading: () => const _VsAiSkeleton(),
        error: (_, __) => const SizedBox.shrink(),
        data: (vsAi) {
          if (vsAi.total == 0) {
            return const _VsAiEmpty();
          }
          return _VsAiContent(vsAi: vsAi);
        },
      ),
    );
  }
}

class _VsAiContent extends StatelessWidget {
  final UserVsAi vsAi;
  const _VsAiContent({required this.vsAi});

  @override
  Widget build(BuildContext context) {
    final userColor =
        vsAi.userBeatsAi ? AppColors.brandGreen : AppColors.brandRed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.compare_arrows_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'You vs AI',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: userColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: userColor.withAlpha(50)),
              ),
              child: Text(
                vsAi.userBeatsAi ? 'You\'re winning!' : 'AI is ahead',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: userColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _VsAiMetric(
                label: 'Your accuracy',
                value: '${vsAi.userAccuracy.toStringAsFixed(1)}%',
                correct: vsAi.userCorrect,
                total: vsAi.total,
                color: userColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VsAiMetric(
                label: 'AI accuracy',
                value: '${vsAi.aiAccuracy.toStringAsFixed(1)}%',
                correct: vsAi.aiCorrect,
                total: vsAi.total,
                color: AppColors.brandPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VsAiMetric extends StatelessWidget {
  final String label, value;
  final int correct, total;
  final Color color;
  const _VsAiMetric({
    required this.label,
    required this.value,
    required this.correct,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'JetBrainsMono',
              )),
          Text('$correct / $total correct',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _VsAiSkeleton extends StatelessWidget {
  const _VsAiSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.brandPurple,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _VsAiEmpty extends StatelessWidget {
  const _VsAiEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You vs AI',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Make your first prediction to see how you compare to AI.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _LeaderboardBody({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No leaderboard data yet',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return Column(
      children: entries.map((e) => _LeaderboardRow(entry: e)).toList(),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const _LeaderboardRow({required this.entry});

  Color get _tierColor {
    switch (entry.accuracyTier) {
      case 'high':
        return AppColors.brandGreen;
      case 'mid':
        return AppColors.brandAmber;
      default:
        return AppColors.brandRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank >= 1 && entry.rank <= 3;
    final rankColors = [
      AppColors.brandAmber,
      const Color(0xFFCCCCCC),
      const Color(0xFFCD7F32),
    ];
    final rankColor =
        isTop3 ? rankColors[entry.rank - 1] : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3
              ? rankColor.withAlpha(40)
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: rankColor,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Coin icon placeholder
          if (entry.imageUrl != null)
            ClipOval(
              child: Image.network(
                entry.imageUrl!,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _CoinInitial(entry.symbol),
              ),
            )
          else
            _CoinInitial(entry.symbol),
          const SizedBox(width: 10),
          // Name & symbol
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  entry.symbol.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.formattedAccuracy,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _tierColor,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
              Text(
                '${entry.correctPredictions}/${entry.totalPredictions}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Bar
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: entry.accuracy / 100,
                backgroundColor: AppColors.borderSubtle,
                valueColor: AlwaysStoppedAnimation(_tierColor),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinInitial extends StatelessWidget {
  final String symbol;
  const _CoinInitial(this.symbol);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          symbol.isEmpty ? '?' : symbol[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.brandGreen,
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandRed.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandRed.withAlpha(30)),
      ),
      child: Text(
        'Failed to load: $message',
        style: const TextStyle(fontSize: 12, color: AppColors.brandRed),
      ),
    );
  }
}

// ── My Predictions Card ────────────────────────────────────────────────────────

class _MyPredictionsCard extends StatelessWidget {
  final AsyncValue<List<PredictionRecord>> mineAsync;
  const _MyPredictionsCard({required this.mineAsync});

  @override
  Widget build(BuildContext context) {
    return mineAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (records) {
        if (records.isEmpty) return const SizedBox.shrink();
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('My Predictions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                  const Spacer(),
                  Text('${records.length} total',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              ...records.take(5).map((r) => _MyPredictionRow(record: r)),
            ],
          ),
        );
      },
    );
  }
}

class _MyPredictionRow extends StatelessWidget {
  final PredictionRecord record;
  const _MyPredictionRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isBull = record.isBullish;
    final dirColor = isBull ? AppColors.brandGreen : AppColors.brandRed;
    final statusColor = record.isCorrect
        ? AppColors.brandGreen
        : record.isPending
            ? AppColors.brandAmber
            : AppColors.brandRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: dirColor.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isBull ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 14,
              color: dirColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.symbol.toUpperCase()} · ${record.direction.toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                if (record.timeframe != null)
                  Text(record.timeframe!,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (record.targetPrice != null)
            Text(
              '\$${record.targetPrice!.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'JetBrainsMono'),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              record.status.toUpperCase(),
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Make Prediction Sheet ──────────────────────────────────────────────────────

class _MakePredictionSheet extends ConsumerStatefulWidget {
  const _MakePredictionSheet();

  @override
  ConsumerState<_MakePredictionSheet> createState() =>
      _MakePredictionSheetState();
}

// Timeframe label → predictionWindowDays value
const _timeframes = [
  ('12H', 0.5),
  ('1D', 1.0),
  ('3D', 3.0),
  ('1W', 7.0),
  ('1M', 30.0),
];

class _MakePredictionSheetState extends ConsumerState<_MakePredictionSheet> {
  // Coin search
  final _coinSearchCtrl = TextEditingController();
  String _coinQuery = '';
  String _selectedCoinId = '';
  String _selectedCoinSymbol = '';
  bool _coinPicked = false;

  // Form fields
  String _direction = 'bullish';
  double _windowDays = 1.0;
  double _confidence = 70;
  final _entryCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _stopCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _coinSearchCtrl.dispose();
    _entryCtrl.dispose();
    _targetCtrl.dispose();
    _stopCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _pickCoin(String coinId, String symbol) {
    setState(() {
      _selectedCoinId = coinId;
      _selectedCoinSymbol = symbol.toUpperCase();
      _coinSearchCtrl.text = '${symbol.toUpperCase()} · $coinId';
      _coinPicked = true;
      _coinQuery = ''; // collapse dropdown
    });
  }

  Future<void> _submit() async {
    final entryPrice = double.tryParse(_entryCtrl.text.trim());
    if (!_coinPicked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a coin'),
        backgroundColor: AppColors.brandAmber,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (entryPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Entry price is required'),
        backgroundColor: AppColors.brandAmber,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    await ref.read(userPredictionsProvider.notifier).submit(
          coinId: _selectedCoinId,
          coinSymbol: _selectedCoinSymbol,
          predictedDirection: _direction,
          entryPrice: entryPrice,
          predictedTarget: double.tryParse(_targetCtrl.text.trim()),
          stopLoss: double.tryParse(_stopCtrl.text.trim()),
          predictionWindowDays: _windowDays,
          confidenceScore: _confidence,
          userReasoning: _reasonCtrl.text.trim(),
        );
    if (!mounted) return;

    final error = ref.read(userPredictionsProvider).submitError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: $error',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.brandRed,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Prediction submitted!',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.brandGreen,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        ref.watch(userPredictionsProvider.select((s) => s.isSubmitting));

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Make a Prediction',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 4),
            const Text('No login needed · tracked by device ID',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 24),

            // ── Coin search ──────────────────────────────────────────────
            const _FormLabel('Coin *'),
            const SizedBox(height: 8),
            TextField(
              controller: _coinSearchCtrl,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search any coin (e.g. Bitcoin, XRP…)',
                hintStyle: const TextStyle(
                    color: AppColors.textDisabled, fontSize: 13),
                filled: true,
                fillColor: AppColors.bgCard,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 18),
                suffixIcon: _coinPicked
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 16),
                        onPressed: () => setState(() {
                          _coinSearchCtrl.clear();
                          _coinPicked = false;
                          _coinQuery = '';
                          _selectedCoinId = '';
                          _selectedCoinSymbol = '';
                        }),
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderSubtle)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderSubtle)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: _coinPicked
                            ? AppColors.brandGreen
                            : AppColors.brandBlue)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => setState(() {
                _coinQuery = v.trim();
                _coinPicked = false;
              }),
            ),
            // Search results dropdown
            if (_coinQuery.length >= 2 && !_coinPicked)
              _CoinSearchResults(
                query: _coinQuery,
                onPick: _pickCoin,
              ),
            const SizedBox(height: 20),

            // ── Direction ───────────────────────────────────────────────
            const _FormLabel('Direction'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DirectionButton(
                    label: 'Bullish',
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.brandGreen,
                    selected: _direction == 'bullish',
                    onTap: () => setState(() => _direction = 'bullish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DirectionButton(
                    label: 'Bearish',
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.brandRed,
                    selected: _direction == 'bearish',
                    onTap: () => setState(() => _direction = 'bearish'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Prediction window ───────────────────────────────────────
            const _FormLabel('Prediction Window'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _timeframes.map((t) {
                final selected = _windowDays == t.$2;
                return GestureDetector(
                  onTap: () => setState(() => _windowDays = t.$2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brandBlue.withAlpha(20)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.brandBlue
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Text(t.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.brandBlue
                              : AppColors.textMuted,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Entry price (required) ──────────────────────────────────
            const _FormLabel('Entry Price *'),
            const SizedBox(height: 8),
            _PriceField(
                controller: _entryCtrl,
                hint: 'e.g. 98000'),
            const SizedBox(height: 16),

            // ── Target & Stop Loss ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FormLabel('Target Price'),
                      const SizedBox(height: 8),
                      _PriceField(
                          controller: _targetCtrl,
                          hint: 'e.g. 105000'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FormLabel('Stop Loss'),
                      const SizedBox(height: 8),
                      _PriceField(
                          controller: _stopCtrl,
                          hint: 'e.g. 94000'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Confidence ──────────────────────────────────────────────
            _FormLabel('Confidence: ${_confidence.toInt()}%'),
            Slider(
              value: _confidence,
              min: 10,
              max: 100,
              divisions: 18,
              activeColor: _confidence >= 70
                  ? AppColors.brandGreen
                  : _confidence >= 50
                      ? AppColors.brandAmber
                      : AppColors.brandRed,
              inactiveColor: AppColors.borderSubtle,
              onChanged: (v) => setState(() => _confidence = v),
            ),
            const SizedBox(height: 16),

            // ── Reasoning ───────────────────────────────────────────────
            const _FormLabel('Your Reasoning (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Why do you think this?',
                hintStyle: const TextStyle(
                    color: AppColors.textDisabled, fontSize: 13),
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderSubtle)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderSubtle)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.brandGreen)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // ── Submit ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor:
                      AppColors.brandGreen.withAlpha(60),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Submit Prediction',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coin Search Results ────────────────────────────────────────────────────────

class _CoinSearchResults extends ConsumerWidget {
  final String query;
  final void Function(String coinId, String symbol) onPick;
  const _CoinSearchResults({required this.query, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coinSearchProvider(query));
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(14),
          child: Center(
              child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.brandGreen),
          )),
        ),
        error: (_, __) => const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Search failed',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
        data: (coins) {
          if (coins.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No coins found',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            );
          }
          return Column(
            children: coins
                .take(6)
                .map((c) => InkWell(
                      onTap: () => onPick(c.id, c.symbol),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            if (c.imageUrl != null)
                              ClipOval(
                                child: Image.network(c.imageUrl!,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.circle,
                                            size: 24,
                                            color: AppColors.textMuted)),
                              )
                            else
                              const Icon(Icons.circle,
                                  size: 24, color: AppColors.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(c.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Text(c.symbol.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontFamily: 'JetBrainsMono')),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ));
  }
}

class _DirectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _DirectionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(20) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _PriceField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
          fontSize: 13, color: Colors.white, fontFamily: 'JetBrainsMono'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textDisabled, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgCard,
        prefixText: '\$',
        prefixStyle: const TextStyle(
            color: AppColors.textMuted, fontFamily: 'JetBrainsMono'),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderSubtle)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderSubtle)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.brandGreen)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
