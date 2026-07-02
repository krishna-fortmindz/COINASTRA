double _n(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
double? _nOpt(dynamic v) => v == null ? null : (v as num?)?.toDouble();

String? _cleanUrl(String? v) {
  if (v == null || v.isEmpty) return null;
  return v
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  try {
    // Handles ISO strings AND unix timestamps (seconds), e.g. publishedOn: 1782305290
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000);
    }
    final asNum = num.tryParse(v.toString());
    if (asNum != null) {
      return DateTime.fromMillisecondsSinceEpoch(asNum.toInt() * 1000);
    }
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

// ── News ──────────────────────────────────────────────────────────────────────

class SentimentNewsItem {
  final String id;
  final String title;
  final String? description;
  final String? url;
  final String? imageUrl;
  final String source;
  final String sentiment;
  final double? sentimentScore;
  final String? rationale;
  final String? aiSummary;
  final DateTime? publishedAt;

  const SentimentNewsItem({
    required this.id,
    required this.title,
    this.description,
    this.url,
    this.imageUrl,
    required this.source,
    required this.sentiment,
    this.sentimentScore,
    this.rationale,
    this.aiSummary,
    this.publishedAt,
  });

  factory SentimentNewsItem.fromJson(Map<String, dynamic> j) {
    // sentiment can arrive as a nested object: {score, label, rationale, summary}
    final sentRaw = j['sentiment'];
    final sentMap = sentRaw is Map ? Map<String, dynamic>.from(sentRaw) : null;

    return SentimentNewsItem(
      id: j['id']?.toString() ??
          j['_id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: j['title']?.toString() ?? '',
      description: j['description']?.toString() ??
          j['summary']?.toString() ??
          j['body']?.toString(),
      url: j['url']?.toString() ?? j['link']?.toString(),
      imageUrl: _cleanUrl(
        j['imageUrl']?.toString() ??
            j['image_url']?.toString() ??
            j['imageurl']?.toString() ??
            j['urlToImage']?.toString() ??
            j['image']?.toString() ??
            j['thumbnail']?.toString() ??
            j['img']?.toString() ??
            j['cover']?.toString(),
      ),
      source:
          j['source']?.toString() ?? j['publisher']?.toString() ?? 'Unknown',
      sentiment: sentMap?['label']?.toString() ??
          j['sentiment']?.toString() ??
          'neutral',
      sentimentScore: _nOpt(sentMap?['score'] ??
          j['sentimentScore'] ??
          j['score'] ??
          j['aiScore']),
      rationale: sentMap?['rationale']?.toString() ??
          j['rationale']?.toString() ??
          j['reasoning']?.toString(),
      aiSummary: sentMap?['summary']?.toString(),
      publishedAt: _date(
        j['publishedAt'] ??
            j['published_at'] ??
            j['publishedOn'] ?? // ← actual API key
            j['pubDate'] ??
            j['createdAt'],
      ),
    );
  }
}

// ── Fear & Greed ──────────────────────────────────────────────────────────────

class FearGreedData {
  final double value;
  final String classification;

  const FearGreedData({required this.value, required this.classification});

  factory FearGreedData.fromJson(Map<String, dynamic> j) => FearGreedData(
        value: _n(j['value']),
        classification: j['classification']?.toString() ??
            j['valueClassification']?.toString() ??
            'Neutral',
      );

  String get tier {
    if (value >= 75) return 'Extreme Greed';
    if (value >= 55) return 'Greed';
    if (value >= 45) return 'Neutral';
    if (value >= 25) return 'Fear';
    return 'Extreme Fear';
  }

  bool get isBullish => value >= 55;
}

// ── Binance Futures ───────────────────────────────────────────────────────────

class BinanceFuturesData {
  final double longAccount;
  final double shortAccount;
  final double longShortRatio;

  const BinanceFuturesData({
    required this.longAccount,
    required this.shortAccount,
    required this.longShortRatio,
  });

  factory BinanceFuturesData.fromJson(Map<String, dynamic> j) =>
      BinanceFuturesData(
        longAccount: _n(j['longAccount'] ??
            j['longAccountPercent'] ??
            j['buyRatio'] ??
            j['longRatio']),
        shortAccount: _n(j['shortAccount'] ??
            j['shortAccountPercent'] ??
            j['sellRatio'] ??
            j['shortRatio']),
        longShortRatio: _n(j['longShortRatio'] ?? j['ratio'] ?? j['lsRatio']),
      );

  bool get isLongDominant => longAccount > 50;

  String get signal {
    if (longAccount >= 60) return 'Strong Longs';
    if (longAccount >= 53) return 'Longs Dominant';
    if (longAccount <= 40) return 'Strong Shorts';
    if (longAccount <= 47) return 'Shorts Dominant';
    return 'Balanced';
  }
}

// ── Social ────────────────────────────────────────────────────────────────────

class SocialPost {
  final String author;
  final String content;
  final String platform;
  final String? sentiment;
  final DateTime? publishedAt;
  final int? likes;
  final int? comments;
  final String? subreddit;

  const SocialPost({
    required this.author,
    required this.content,
    required this.platform,
    this.sentiment,
    this.publishedAt,
    this.likes,
    this.comments,
    this.subreddit,
  });

  factory SocialPost.fromJson(Map<String, dynamic> j) => SocialPost(
        author: j['author']?.toString() ??
            j['username']?.toString() ??
            j['user']?.toString() ??
            'Unknown',
        content: j['content']?.toString() ??
            j['text']?.toString() ??
            j['body']?.toString() ??
            '',
        platform: j['platform']?.toString() ?? 'unknown',
        sentiment: j['sentiment']?.toString(),
        publishedAt:
            _date(j['publishedAt'] ?? j['created_at'] ?? j['timestamp']),
        likes: (j['likes'] ?? j['upvotes'] ?? j['score'] as num?)?.toInt(),
        comments: (j['comments'] ?? j['numComments'] as num?)?.toInt(),
        subreddit: j['subreddit']?.toString(),
      );
}

class PlatformSentiment {
  final double bullishPercent;
  final double bearishPercent;
  final double neutralPercent;
  final int totalMentions;
  final double? volumeChange24h;
  final List<SocialPost> posts;

  const PlatformSentiment({
    required this.bullishPercent,
    required this.bearishPercent,
    required this.neutralPercent,
    required this.totalMentions,
    this.volumeChange24h,
    required this.posts,
  });

  factory PlatformSentiment.fromJson(Map<String, dynamic> j) {
    final rawPosts = j['posts'] ?? j['tweets'] ?? j['items'] ?? [];
    return PlatformSentiment(
      bullishPercent:
          _n(j['bullishPercent'] ?? j['bullish_percent'] ?? j['bullish']),
      bearishPercent:
          _n(j['bearishPercent'] ?? j['bearish_percent'] ?? j['bearish']),
      neutralPercent:
          _n(j['neutralPercent'] ?? j['neutral_percent'] ?? j['neutral']),
      totalMentions:
          (j['totalMentions'] ?? j['total_mentions'] ?? j['mentions'] as num?)
                  ?.toInt() ??
              0,
      volumeChange24h: _nOpt(j['volumeChange24h'] ?? j['volume_change']),
      posts: (rawPosts as List)
          .whereType<Map>()
          .map((m) => SocialPost.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class SocialSentimentData {
  final FearGreedData? fearAndGreed;
  final BinanceFuturesData? binanceFutures;
  final PlatformSentiment? twitter;
  final PlatformSentiment? reddit;

  const SocialSentimentData({
    this.fearAndGreed,
    this.binanceFutures,
    this.twitter,
    this.reddit,
  });

  double get overallBullish {
    if (fearAndGreed != null) return fearAndGreed!.value;
    final t = twitter?.bullishPercent ?? 0;
    final r = reddit?.bullishPercent ?? 0;
    if (twitter != null && reddit != null) return (t + r) / 2;
    return t + r;
  }

  factory SocialSentimentData.fromJson(Map<String, dynamic> j) {
    final fgRaw = j['fearAndGreed'] ?? j['fear_and_greed'] ?? j['fearGreed'];
    final bfRaw = j['binanceFutures'] ?? j['binance_futures'] ?? j['futures'];
    final tRaw = j['twitter'] ?? j['Twitter'];
    final rRaw = j['reddit'] ?? j['Reddit'];
    return SocialSentimentData(
      fearAndGreed: fgRaw is Map
          ? FearGreedData.fromJson(Map<String, dynamic>.from(fgRaw))
          : null,
      binanceFutures: bfRaw is Map
          ? BinanceFuturesData.fromJson(Map<String, dynamic>.from(bfRaw))
          : null,
      twitter: tRaw is Map
          ? PlatformSentiment.fromJson(Map<String, dynamic>.from(tRaw))
          : null,
      reddit: rRaw is Map
          ? PlatformSentiment.fromJson(Map<String, dynamic>.from(rRaw))
          : null,
    );
  }
}

// ── Coin Signals ──────────────────────────────────────────────────────────────

class CoinSignal {
  final String type;
  final String signal;
  final double? confidence;
  final String? description;

  const CoinSignal({
    required this.type,
    required this.signal,
    this.confidence,
    this.description,
  });

  factory CoinSignal.fromJson(Map<String, dynamic> j) => CoinSignal(
        type: j['type']?.toString() ?? 'general',
        signal: j['signal']?.toString() ?? 'neutral',
        confidence: _nOpt(j['confidence'] ?? j['score']),
        description: j['description']?.toString() ?? j['message']?.toString(),
      );
}

class CoinSentimentData {
  final String coinId;
  final String symbol;
  final String overallSentiment;
  final double overallScore;
  final List<CoinSignal> signals;
  final String? aiSummary;
  final double? price;
  final double? priceChange24h;

  const CoinSentimentData({
    required this.coinId,
    required this.symbol,
    required this.overallSentiment,
    required this.overallScore,
    required this.signals,
    this.aiSummary,
    this.price,
    this.priceChange24h,
  });

  factory CoinSentimentData.fromJson(Map<String, dynamic> j) {
    final rawSignals = j['signals'] ?? [];
    var signals = (rawSignals as List)
        .whereType<Map>()
        .map((m) => CoinSignal.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    if (signals.isEmpty) {
      final fgRaw = j['fearAndGreed'] ?? j['fear_and_greed'];
      if (fgRaw is Map) {
        final fg = Map<String, dynamic>.from(fgRaw);
        final fgVal = _n(fg['value']);
        signals.add(CoinSignal(
          type: 'sentiment',
          signal: fgVal >= 60
              ? 'bullish'
              : fgVal <= 40
                  ? 'bearish'
                  : 'neutral',
          confidence: fgVal,
          description:
              'Fear & Greed: ${fg['classification'] ?? _fearGreedLabel(fgVal)}',
        ));
      }
      final nvtRaw = j['nvtRatio'] ?? j['nvt'];
      if (nvtRaw is Map) {
        final nvt = Map<String, dynamic>.from(nvtRaw);
        signals.add(CoinSignal(
          type: 'onchain',
          signal: _nvtSignal(nvt['signal']?.toString() ?? ''),
          description: 'NVT Ratio: ${nvt['value']}  ·  ${nvt['signal'] ?? ''}',
        ));
      }
      final newsSent = j['newsSentiment']?.toString();
      if (newsSent != null) {
        signals.add(CoinSignal(
          type: 'news',
          signal: newsSent,
          description: 'Live AI news sentiment analysis',
        ));
      }
      final dRaw = j['derivatives'];
      if (dRaw is Map) {
        final d = Map<String, dynamic>.from(dRaw);
        final lsr = _nOpt(d['longShortRatio'] ?? d['lsRatio']) ?? 1.0;
        signals.add(CoinSignal(
          type: 'technical',
          signal: lsr > 1.15
              ? 'bullish'
              : lsr < 0.85
                  ? 'bearish'
                  : 'neutral',
          confidence: (lsr * 50).clamp(0, 100),
          description: 'Long/Short Ratio: ${lsr.toStringAsFixed(3)}',
        ));
      }
    }

    return CoinSentimentData(
      coinId: j['coinId']?.toString() ?? j['coin_id']?.toString() ?? '',
      symbol: j['symbol']?.toString() ?? '',
      overallSentiment: j['overallSentiment']?.toString() ??
          j['sentiment']?.toString() ??
          'neutral',
      overallScore: _n(j['overallScore'] ?? j['score'] ?? j['sentimentScore']),
      signals: signals,
      aiSummary: j['aiSummary']?.toString() ??
          j['summary']?.toString() ??
          j['consensus']?.toString(),
      price: _nOpt(j['price'] ?? j['currentPrice']),
      priceChange24h: _nOpt(j['priceChange24h'] ?? j['change24h']),
    );
  }
}

String _fearGreedLabel(double v) {
  if (v >= 75) return 'Extreme Greed';
  if (v >= 55) return 'Greed';
  if (v >= 45) return 'Neutral';
  if (v >= 25) return 'Fear';
  return 'Extreme Fear';
}

String _nvtSignal(String s) {
  final lower = s.toLowerCase();
  if (lower.contains('over')) return 'bearish';
  if (lower.contains('under')) return 'bullish';
  return 'neutral';
}

// ── On-Chain ──────────────────────────────────────────────────────────────────

class OnChainIndicator {
  final String name;
  final String value;
  final String signal;
  final String description;

  const OnChainIndicator({
    required this.name,
    required this.value,
    required this.signal,
    required this.description,
  });

  factory OnChainIndicator.fromJson(Map<String, dynamic> j) => OnChainIndicator(
        name: j['name']?.toString() ?? '',
        value: j['value']?.toString() ?? '—',
        signal: j['signal']?.toString() ?? 'Neutral',
        description:
            j['description']?.toString() ?? j['explanation']?.toString() ?? '',
      );
}

class ExchangeFlows {
  final double inflow;
  final double outflow;
  final double netFlow;
  final double? reserve;

  const ExchangeFlows({
    required this.inflow,
    required this.outflow,
    required this.netFlow,
    this.reserve,
  });

  factory ExchangeFlows.fromJson(Map<String, dynamic> j) => ExchangeFlows(
        inflow: _n(j['inflow'] ?? j['exchangeInflow']),
        outflow: _n(j['outflow'] ?? j['exchangeOutflow']),
        netFlow: _n(j['netFlow'] ?? j['net_flow']),
        reserve: _nOpt(j['reserve'] ?? j['exchangeReserve']),
      );
}

class OnChainSentimentData {
  final List<OnChainIndicator> indicators;
  final ExchangeFlows? flows;
  final String? aiSummary;

  const OnChainSentimentData({
    required this.indicators,
    this.flows,
    this.aiSummary,
  });

  factory OnChainSentimentData.fromJson(Map<String, dynamic> j) {
    final indicators = <OnChainIndicator>[];

    // Parse new structure: { btc: { nvtRatio, derivatives }, eth: { ... } }
    for (final entry in [
      ('BTC', j['btc'] ?? j['bitcoin']),
      ('ETH', j['eth'] ?? j['ethereum']),
    ]) {
      final label = entry.$1;
      final coinData = entry.$2;
      if (coinData is Map<String, dynamic>) {
        _extractCoinIndicators(label, coinData, indicators);
      }
    }

    // Fallback to old structure with indicators/metrics list
    if (indicators.isEmpty) {
      final rawInd = j['indicators'] ?? j['metrics'] ?? [];
      (rawInd as List)
          .whereType<Map>()
          .map((m) => OnChainIndicator.fromJson(Map<String, dynamic>.from(m)))
          .forEach(indicators.add);
    }

    final rawFlows = j['exchangeFlows'] ?? j['flows'];
    return OnChainSentimentData(
      indicators: indicators,
      flows: rawFlows is Map
          ? ExchangeFlows.fromJson(Map<String, dynamic>.from(rawFlows))
          : null,
      aiSummary: j['aiSummary']?.toString() ?? j['summary']?.toString(),
    );
  }
}

void _extractCoinIndicators(
  String prefix,
  Map<String, dynamic> coinData,
  List<OnChainIndicator> out,
) {
  final nvtRaw = coinData['nvtRatio'] ?? coinData['nvt'];
  if (nvtRaw is Map<String, dynamic>) {
    final val = nvtRaw['value'];
    final sig = nvtRaw['signal']?.toString() ?? 'Neutral';
    out.add(OnChainIndicator(
      name: '$prefix NVT Ratio',
      value: val?.toString() ?? '—',
      signal: sig,
      description:
          'Network Value ÷ 24h Transaction Volume. Higher = overvalued.',
    ));
  }

  final dRaw = coinData['derivatives'];
  if (dRaw is Map<String, dynamic>) {
    final fr = dRaw['fundingRate'];
    if (fr != null) {
      final frVal = double.tryParse(fr.toString()) ?? 0;
      final frPct = (frVal * 100).toStringAsFixed(4);
      out.add(OnChainIndicator(
        name: '$prefix Funding Rate',
        value: '${frVal >= 0 ? '+' : ''}$frPct%',
        signal: frVal > 0.0005
            ? 'Longs Paying'
            : frVal < -0.0005
                ? 'Shorts Paying'
                : 'Neutral',
        description: 'Perpetual futures 8h funding rate.',
      ));
    }
    final oi = dRaw['openInterest'];
    if (oi != null) {
      final oiVal = double.tryParse(oi.toString()) ?? 0;
      out.add(OnChainIndicator(
        name: '$prefix Open Interest',
        value: _formatLarge(oiVal),
        signal: 'Active',
        description: 'Total value of open futures positions.',
      ));
    }
    final lsr = dRaw['longShortRatio'] ?? dRaw['lsRatio'];
    if (lsr != null) {
      final lsrVal = double.tryParse(lsr.toString()) ?? 1.0;
      out.add(OnChainIndicator(
        name: '$prefix L/S Ratio',
        value: lsrVal.toStringAsFixed(3),
        signal: lsrVal > 1.15
            ? 'Bullish'
            : lsrVal < 0.85
                ? 'Bearish'
                : 'Neutral',
        description: 'Long vs short account ratio from Binance Futures.',
      ));
    }
  }
}

String _formatLarge(double v) {
  final abs = v.abs();
  if (abs >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
  if (abs >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
  if (abs >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
