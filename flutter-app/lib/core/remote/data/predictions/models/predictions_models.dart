// ── CoinId → display name / symbol lookup ─────────────────────────────────────

const _coinNames = <String, String>{
  'bitcoin': 'Bitcoin',
  'ethereum': 'Ethereum',
  'solana': 'Solana',
  'binancecoin': 'BNB',
  'ripple': 'XRP',
  'cardano': 'Cardano',
  'avalanche-2': 'Avalanche',
  'dogecoin': 'Dogecoin',
  'polkadot': 'Polkadot',
  'chainlink': 'Chainlink',
  'matic-network': 'Polygon',
  'shiba-inu': 'Shiba Inu',
  'tron': 'TRON',
  'litecoin': 'Litecoin',
  'uniswap': 'Uniswap',
  'arbitrum': 'Arbitrum',
  'optimism': 'Optimism',
  'near': 'NEAR',
  'aptos': 'Aptos',
  'sui': 'Sui',
};

const _coinSymbols = <String, String>{
  'bitcoin': 'BTC',
  'ethereum': 'ETH',
  'solana': 'SOL',
  'binancecoin': 'BNB',
  'ripple': 'XRP',
  'cardano': 'ADA',
  'avalanche-2': 'AVAX',
  'dogecoin': 'DOGE',
  'polkadot': 'DOT',
  'chainlink': 'LINK',
  'matic-network': 'MATIC',
  'shiba-inu': 'SHIB',
  'tron': 'TRX',
  'litecoin': 'LTC',
  'uniswap': 'UNI',
  'arbitrum': 'ARB',
  'optimism': 'OP',
  'near': 'NEAR',
  'aptos': 'APT',
  'sui': 'SUI',
};

String _nameFromCoinId(String coinId) =>
    _coinNames[coinId] ??
    coinId
        .split('-')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

String _symbolFromCoinId(String coinId) =>
    _coinSymbols[coinId] ?? coinId.toUpperCase().split('-').first;

// ── Leaderboard ───────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final int rank;
  final String coinId;
  final String symbol;
  final String name;
  final String? imageUrl;
  final double accuracy;
  final int totalPredictions;
  final int correctPredictions;
  final String period;

  const LeaderboardEntry({
    required this.rank,
    required this.coinId,
    required this.symbol,
    required this.name,
    this.imageUrl,
    required this.accuracy,
    required this.totalPredictions,
    required this.correctPredictions,
    required this.period,
  });

  // [rankOverride] is passed from the repo when the backend omits rank
  factory LeaderboardEntry.fromJson(Map<String, dynamic> j,
      {int rankOverride = 0}) {
    final coinId =
        j['coinId']?.toString() ?? j['coin_id']?.toString() ?? j['id']?.toString() ?? '';

    // Backend doesn't always return name/symbol — derive from coinId
    final symbol = j['symbol']?.toString().isNotEmpty == true
        ? j['symbol'].toString()
        : _symbolFromCoinId(coinId);
    final name = j['name']?.toString().isNotEmpty == true
        ? j['name'].toString()
        : _nameFromCoinId(coinId);

    final rank = (j['rank'] as num?)?.toInt() ??
        (j['position'] as num?)?.toInt() ??
        rankOverride;

    return LeaderboardEntry(
      rank: rank,
      coinId: coinId,
      symbol: symbol,
      name: name,
      imageUrl: j['imageUrl']?.toString() ??
          j['image']?.toString() ??
          j['logo']?.toString(),
      accuracy: (j['accuracyRate'] as num?)?.toDouble() ??
          (j['accuracy'] as num?)?.toDouble() ??
          (j['winRate'] as num?)?.toDouble() ??
          0,
      totalPredictions: (j['totalPredictions'] as num?)?.toInt() ??
          (j['total'] as num?)?.toInt() ??
          0,
      correctPredictions: (j['correctPredictions'] as num?)?.toInt() ??
          (j['correct'] as num?)?.toInt() ??
          0,
      period: j['timeframe']?.toString() ??
          j['period']?.toString() ??
          '30d',
    );
  }

  String get formattedAccuracy => '${accuracy.toStringAsFixed(1)}%';

  // 'high' >= 70, 'mid' >= 55, 'low' < 55 — UI maps to colors
  String get accuracyTier {
    if (accuracy >= 70) return 'high';
    if (accuracy >= 55) return 'mid';
    return 'low';
  }
}

// ── Coin Accuracy ─────────────────────────────────────────────────────────────

class CoinAccuracy {
  final String coinId;
  final String symbol;
  final double accuracy;
  final int totalPredictions;
  final int correctPredictions;
  final String period;

  const CoinAccuracy({
    required this.coinId,
    required this.symbol,
    required this.accuracy,
    required this.totalPredictions,
    required this.correctPredictions,
    required this.period,
  });

  factory CoinAccuracy.fromJson(Map<String, dynamic> j) => CoinAccuracy(
        coinId: j['coinId']?.toString() ?? j['coin_id']?.toString() ?? '',
        symbol: j['symbol']?.toString() ?? '',
        accuracy: (j['accuracyRate'] as num?)?.toDouble() ??
            (j['accuracy'] as num?)?.toDouble() ?? 0,
        totalPredictions:
            (j['totalPredictions'] as num?)?.toInt() ??
            (j['total'] as num?)?.toInt() ?? 0,
        correctPredictions:
            (j['correctPredictions'] as num?)?.toInt() ??
            (j['correct'] as num?)?.toInt() ?? 0,
        period: j['timeframe']?.toString() ?? j['period']?.toString() ?? '30d',
      );

  String get formattedAccuracy => '${accuracy.toStringAsFixed(1)}%';

  static const empty = CoinAccuracy(
    coinId: '',
    symbol: '',
    accuracy: 0,
    totalPredictions: 0,
    correctPredictions: 0,
    period: '30d',
  );
}

// ── Prediction History ────────────────────────────────────────────────────────

class PredictionRecord {
  final String id;
  final String coinId;
  final String symbol;
  final String direction;
  final double? targetPrice;
  final double? actualPrice;
  final String status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String? timeframe;
  final double? confidence;

  const PredictionRecord({
    required this.id,
    required this.coinId,
    required this.symbol,
    required this.direction,
    this.targetPrice,
    this.actualPrice,
    required this.status,
    this.createdAt,
    this.resolvedAt,
    this.timeframe,
    this.confidence,
  });

  factory PredictionRecord.fromJson(Map<String, dynamic> j) => PredictionRecord(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        coinId: j['coinId']?.toString() ?? j['coin_id']?.toString() ?? '',
        symbol: j['symbol']?.toString() ?? '',
        direction: j['direction']?.toString() ?? j['signal']?.toString() ?? '',
        targetPrice: (j['targetPrice'] as num?)?.toDouble() ??
            (j['target_price'] as num?)?.toDouble(),
        actualPrice: (j['actualPrice'] as num?)?.toDouble() ??
            (j['actual_price'] as num?)?.toDouble(),
        status: j['status']?.toString() ?? 'pending',
        createdAt: _parseDate(j['createdAt'] ?? j['created_at']),
        resolvedAt: _parseDate(j['resolvedAt'] ?? j['resolved_at']),
        timeframe: j['timeframe']?.toString(),
        confidence: (j['confidence'] as num?)?.toDouble(),
      );

  bool get isCorrect => status == 'correct' || status == 'win';
  bool get isPending => status == 'pending';
  bool get isBullish =>
      direction.toLowerCase() == 'long' ||
      direction.toLowerCase() == 'buy' ||
      direction.toLowerCase() == 'bullish';
}

// ── Post Mortem ───────────────────────────────────────────────────────────────

class PostMortem {
  final String id;
  final String coinId;
  final String symbol;
  final String predictedDirection;
  final String actualOutcome;
  final String explanation;
  final List<String> keyMistakes;
  final List<String> lessons;
  final DateTime? date;

  const PostMortem({
    required this.id,
    required this.coinId,
    required this.symbol,
    required this.predictedDirection,
    required this.actualOutcome,
    required this.explanation,
    required this.keyMistakes,
    required this.lessons,
    this.date,
  });

  factory PostMortem.fromJson(Map<String, dynamic> j) => PostMortem(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        coinId: j['coinId']?.toString() ?? j['coin_id']?.toString() ?? '',
        symbol: j['symbol']?.toString() ?? '',
        predictedDirection:
            j['predictedDirection']?.toString() ??
            j['predicted']?.toString() ?? '',
        actualOutcome:
            j['actualOutcome']?.toString() ??
            j['actual']?.toString() ?? '',
        explanation: j['explanation']?.toString() ?? j['reason']?.toString() ?? '',
        keyMistakes: _parseStringList(j['keyMistakes'] ?? j['mistakes']),
        lessons: _parseStringList(j['lessons'] ?? j['takeaways']),
        date: _parseDate(j['date'] ?? j['createdAt'] ?? j['created_at']),
      );
}

// ── User Prediction ───────────────────────────────────────────────────────────

class UserPrediction {
  final String? userId;              // optional — backend stores as "guest" if absent
  final String coinId;               // e.g. "ripple"
  final String coinSymbol;           // e.g. "XRP"
  final String predictedDirection;   // "bullish" | "bearish"
  final double entryPrice;           // required by backend
  final double? predictedTarget;
  final double? stopLoss;
  final double? predictionWindowDays; // 0.5 = 12h, 1 = 1d, 7 = 1w, 30 = 1m
  final String? userReasoning;
  final double? confidenceScore;

  const UserPrediction({
    this.userId,
    required this.coinId,
    required this.coinSymbol,
    required this.predictedDirection,
    required this.entryPrice,
    this.predictedTarget,
    this.stopLoss,
    this.predictionWindowDays,
    this.userReasoning,
    this.confidenceScore,
  });

  Map<String, dynamic> toJson() => {
        if (userId != null && userId!.isNotEmpty) 'userId': userId,
        'coinId': coinId,
        'coinSymbol': coinSymbol,
        'predictedDirection': predictedDirection,
        'entryPrice': entryPrice,
        if (predictedTarget != null) 'predictedTarget': predictedTarget,
        if (stopLoss != null) 'stopLoss': stopLoss,
        if (predictionWindowDays != null) 'predictionWindowDays': predictionWindowDays,
        if (userReasoning != null && userReasoning!.isNotEmpty) 'userReasoning': userReasoning,
        if (confidenceScore != null) 'confidenceScore': confidenceScore,
      };
}

// ── User vs AI ────────────────────────────────────────────────────────────────

class UserVsAi {
  final String userId;
  final double userAccuracy;
  final double aiAccuracy;
  final int userCorrect;
  final int aiCorrect;
  final int total;
  final List<VsAiEntry> breakdown;

  const UserVsAi({
    required this.userId,
    required this.userAccuracy,
    required this.aiAccuracy,
    required this.userCorrect,
    required this.aiCorrect,
    required this.total,
    required this.breakdown,
  });

  factory UserVsAi.fromJson(Map<String, dynamic> j) => UserVsAi(
        userId: j['userId']?.toString() ?? '',
        userAccuracy: (j['userAccuracy'] as num?)?.toDouble() ?? 0,
        aiAccuracy: (j['aiAccuracy'] as num?)?.toDouble() ?? 0,
        userCorrect: (j['userCorrect'] as num?)?.toInt() ?? 0,
        aiCorrect: (j['aiCorrect'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        breakdown: ((j['breakdown'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(VsAiEntry.fromJson)
            .toList(),
      );

  bool get userBeatsAi => userAccuracy > aiAccuracy;

  static const empty = UserVsAi(
    userId: '',
    userAccuracy: 0,
    aiAccuracy: 0,
    userCorrect: 0,
    aiCorrect: 0,
    total: 0,
    breakdown: [],
  );
}

class VsAiEntry {
  final String coinId;
  final String symbol;
  final bool userCorrect;
  final bool aiCorrect;
  final String direction;
  final DateTime? date;

  const VsAiEntry({
    required this.coinId,
    required this.symbol,
    required this.userCorrect,
    required this.aiCorrect,
    required this.direction,
    this.date,
  });

  factory VsAiEntry.fromJson(Map<String, dynamic> j) => VsAiEntry(
        coinId: j['coinId']?.toString() ?? '',
        symbol: j['symbol']?.toString() ?? '',
        userCorrect: j['userCorrect'] == true,
        aiCorrect: j['aiCorrect'] == true,
        direction: j['direction']?.toString() ?? '',
        date: _parseDate(j['date'] ?? j['createdAt']),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

List<String> _parseStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}
