class NewListing {
  final String coinId;
  final String symbol;
  final String name;
  final String imageUrl;
  final String exchange;
  final String listingDate;
  final double price;
  final double change24h;
  final double volumeSurge;
  final int socialSentiment;
  final int momentumScore;
  final int potentialScore;
  final String riskLevel;
  final String category;
  final bool whaleActivity;
  final bool smartMoney;

  const NewListing({
    required this.coinId,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.exchange,
    required this.listingDate,
    required this.price,
    required this.change24h,
    required this.volumeSurge,
    required this.socialSentiment,
    required this.momentumScore,
    required this.potentialScore,
    required this.riskLevel,
    required this.category,
    required this.whaleActivity,
    required this.smartMoney,
  });

  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'meme':
        return '🐸';
      case 'ai':
        return '🤖';
      case 'rwa':
        return '🏦';
      case 'gaming':
        return '🎮';
      case 'defi':
        return '💎';
      default:
        return '🪙';
    }
  }

  String get formattedPrice {
    if (price >= 1000) {
      return '\$${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    if (price >= 0.01) return '\$${price.toStringAsFixed(4)}';
    return '\$${price.toStringAsFixed(6)}';
  }

  String get formattedChange =>
      '${change24h >= 0 ? '+' : ''}${change24h.toStringAsFixed(1)}%';

  String get formattedVolumeSurge =>
      volumeSurge > 0 ? '${volumeSurge.toStringAsFixed(0)}x' : '—';

  static String _normalizeRisk(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('high') || r.contains('very')) return 'High';
    if (r.contains('low')) return 'Low';
    return 'Medium';
  }

  static String _formatRelativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  factory NewListing.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] ?? json['currentPrice'] as num?)?.toDouble() ??
        double.tryParse(json['price']?.toString() ?? '') ??
        0;
    final change = (json['change24h'] ??
                json['priceChange24h'] ??
                json['change'] as num?)
            ?.toDouble() ??
        double.tryParse(
                (json['change24h'] ?? json['priceChange24h'] ?? json['change'])
                        ?.toString() ??
                    '') ??
        0;

    double volumeSurge = 0;
    final rawVol = json['volumeSurge'] ?? json['volume_surge'];
    if (rawVol != null) {
      volumeSurge =
          double.tryParse(rawVol.toString().replaceAll(RegExp(r'[xX]'), '')) ??
              0;
    }

    String listingDate = json['listingDate']?.toString() ??
        json['listing_date']?.toString() ??
        json['listedAt']?.toString() ??
        '';
    if (listingDate.isNotEmpty) {
      final dt = DateTime.tryParse(listingDate);
      if (dt != null) listingDate = _formatRelativeDate(dt);
    }
    if (listingDate.isEmpty) listingDate = 'Recently';

    final category = json['category']?.toString() ??
        json['narrative']?.toString() ??
        'Other';

    return NewListing(
      coinId: json['id']?.toString() ??
          json['coinId']?.toString() ??
          json['coin_id']?.toString() ??
          (json['symbol']?.toString() ?? '').toLowerCase(),
      symbol: (json['symbol'] as String? ?? '').toUpperCase(),
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ??
          json['image']?.toString() ??
          json['logo']?.toString() ??
          '',
      exchange: json['exchange']?.toString() ??
          json['exchangeName']?.toString() ??
          '—',
      listingDate: listingDate,
      price: price,
      change24h: change,
      volumeSurge: volumeSurge,
      socialSentiment:
          (json['socialSentiment'] ?? json['social_sentiment'] as num?)
                  ?.toInt() ??
              0,
      momentumScore:
          (json['momentumScore'] ?? json['momentum_score'] as num?)?.toInt() ??
              0,
      potentialScore: (json['potentialScore'] ??
                  json['potential_score'] ??
                  json['aiScore'] as num?)
              ?.toInt() ??
          0,
      riskLevel: _normalizeRisk(json['riskLevel']?.toString() ??
          json['risk_level']?.toString() ??
          'Medium'),
      category: category,
      whaleActivity: json['whaleActivity'] as bool? ??
          json['whale_activity'] as bool? ??
          false,
      smartMoney:
          json['smartMoney'] as bool? ?? json['smart_money'] as bool? ?? false,
    );
  }
}

class AiListingScore {
  final int score;
  final String summary;
  final List<String> riskFlags;

  const AiListingScore({
    required this.score,
    required this.summary,
    required this.riskFlags,
  });

  static const empty = AiListingScore(score: 0, summary: '', riskFlags: []);

  factory AiListingScore.fromJson(Map<String, dynamic> json) => AiListingScore(
        score: (json['score'] ??
                    json['aiScore'] ??
                    json['ai_score'] ??
                    json['potentialScore'] as num?)
                ?.toInt() ??
            0,
        summary: json['summary']?.toString() ??
            json['reason']?.toString() ??
            json['description']?.toString() ??
            json['analysis']?.toString() ??
            '',
        riskFlags: ((json['riskFlags'] ??
                        json['risk_flags'] ??
                        json['risks']) as List? ??
                    [])
                .map((f) => f.toString())
                .toList(),
      );
}
