class EndPoints {
  EndPoints._();

  // ─────────────────────────────────────────────────────────────
  // Backend Base URLs
  // ─────────────────────────────────────────────────────────────

  static const String _env =
      String.fromEnvironment('ENV', defaultValue: 'prod');

  static const String baseUrl = _env == 'dev'
      ? 'http://10.255.251.45:5000'
      : 'https://coinastra.duckdns.org';

  static const String apiBaseUrl = '$baseUrl/api/v1';
  static const String dashboardBaseUrl = '$apiBaseUrl/dashboard';
  static const String aiBaseUrl = '$baseUrl/api/ai';

  // Socket.IO — connect through dev proxy to avoid browser CORS restrictions
  static const String socketUrl = baseUrl;
  static const String socketPath = '/socket.io';

  // ─────────────────────────────────────────────────────────────
  // Auth / Token
  // ─────────────────────────────────────────────────────────────

  static const String generateNewToken = '$apiBaseUrl/token/generate';

  // ─────────────────────────────────────────────────────────────
  // Dashboard REST APIs
  // ─────────────────────────────────────────────────────────────

  static const String dashboardSummary = '$dashboardBaseUrl/summary';

  static const String marketCoins = '$dashboardBaseUrl/markets';

  static const String trendingCoins = '$dashboardBaseUrl/trending';

  static const String globalMarket = '$dashboardBaseUrl/global';

  static const String fearGreedIndex = '$dashboardBaseUrl/fear-greed';

  static const String klines = '$dashboardBaseUrl/klines';

  static const String orderBook = '$dashboardBaseUrl/order-book';

  static const String ticker24hr = '$dashboardBaseUrl/ticker-24hr';

  static const String exchangeInfo = '$dashboardBaseUrl/exchange-info';

  static const String fundingRates = '$dashboardBaseUrl/funding-rates';
  static const String marketAiAnalysis = '$apiBaseUrl/dashboard/trade-analysis';

  // ─────────────────────────────────────────────────────────────
  // Trade Now — AI Analysis APIs
  // ─────────────────────────────────────────────────────────────

  // Trade Now
  static const String analysisSignal = '$apiBaseUrl/analysis/signal';
  static const String analysisSentiment = '$apiBaseUrl/analysis/sentiment';
  static const String analysisOpenInterest =
      '$apiBaseUrl/analysis/open-interest';
  static const String analysisLongShort = '$apiBaseUrl/analysis/long-short';
  static const String analysisLiquidations =
      '$apiBaseUrl/analysis/liquidations';
  static const String analysisHistory = '$apiBaseUrl/analysis/history';

  // Order Book
  static const String analysisLevels = '$apiBaseUrl/analysis/levels';

  // Charts — indicators & pattern overlay
  static const String analysisIndicators = '$apiBaseUrl/analysis/indicators';
  static const String analysisPatterns = '$apiBaseUrl/analysis/patterns';
  static const String detectPattern = '$apiBaseUrl/charts/detect-pattern';

  // Feedback
  static const String feedback = '$apiBaseUrl/feedback';

  // ─────────────────────────────────────────────────────────────
  // New Listings (NEW — backend to build)
  // GET ?page=1&limit=20
  // ─────────────────────────────────────────────────────────────
  static const String newListings = '$dashboardBaseUrl/new-listings';

  // GET ?coinId=bitcoin
  static const String newListingsAiScore = '$aiBaseUrl/listings/score';

  // ─────────────────────────────────────────────────────────────
  // On-chain / Sentiment (NEW — backend to build)
  // ─────────────────────────────────────────────────────────────
  static const String sentimentNews = '$baseUrl/api/sentiment/news';
  static String sentimentNewsWithParams({int page = 1, int limit = 20}) =>
      Uri.parse('$baseUrl/api/sentiment/news')
          .replace(queryParameters: {'page': '$page', 'limit': '$limit'})
          .toString();
  static const String sentimentSocial = '$baseUrl/api/sentiment/social';
  static String sentimentCoin(String coinId) =>
      '$baseUrl/api/sentiment/coins/$coinId';
  static const String sentimentOnChain = '$baseUrl/api/sentiment/onchain';
  // ─────────────────────────────────────────────────────────────
  // Portfolio
  // ─────────────────────────────────────────────────────────────
  static const String portfolio = '$apiBaseUrl/portfolio';
  static const String portfolioPositions = '$apiBaseUrl/portfolio/positions';
  static const String portfolioSummary = '$apiBaseUrl/portfolio/summary';
  static const String portfolioTips = '$apiBaseUrl/portfolio/tips';

  static String portfolioPosition(String id) => '$portfolioPositions/$id';
  static String closePortfolioPosition(String id) =>
      '$portfolioPositions/$id/close';

  static String portfolioWithParams({
    String status = 'open',
    String currency = 'USD',
  }) =>
      Uri.parse(portfolio).replace(queryParameters: {
        'status': status,
        'currency': currency,
      }).toString();

  // kept for backward compatibility
  static const String portfolioHoldings = '$apiBaseUrl/portfolio/holdings';
  static const String portfolioPerformance =
      '$apiBaseUrl/portfolio/performance';

  // ─────────────────────────────────────────────────────────────
  // Alerts (NEW — backend to build)
  // ─────────────────────────────────────────────────────────────
  static const String alerts = '$apiBaseUrl/alerts';
  static const String alertsHistory = '$apiBaseUrl/alerts/history';

  // ─────────────────────────────────────────────────────────────
  // Trade Journal (NEW — backend to build)
  // ─────────────────────────────────────────────────────────────
  static const String journal = '$baseUrl/api/journal';
  static const String journalStats = '$baseUrl/api/journal/stats';

  // ─────────────────────────────────────────────────────────────
  // AI Chat (NEW — backend to build)
  // ─────────────────────────────────────────────────────────────
  static const String aiChat = '$apiBaseUrl/ai/chat';
  static const String aiChatHistory = '$apiBaseUrl/ai/chat/history';

  // ─────────────────────────────────────────────────────────────
  // Predictions
  // ─────────────────────────────────────────────────────────────
  static const String predictionsLeaderboard =
      '$apiBaseUrl/predictions/leaderboard';
  static const String predictionsUser = '$apiBaseUrl/predictions/user';
  static const String predictionsUserMine = '$apiBaseUrl/predictions/user/mine';
  static const String predictionsUserVsAi =
      '$apiBaseUrl/predictions/user/vs-ai';

  static String predictionAccuracy(String coinId) =>
      '$apiBaseUrl/predictions/$coinId/accuracy';

  static String predictionHistory(String coinId) =>
      '$apiBaseUrl/predictions/$coinId/history';

  static String predictionPostMortems(String coinId) =>
      '$apiBaseUrl/predictions/$coinId/post-mortems';

  // ─────────────────────────────────────────────────────────────
  // Dynamic Dashboard APIs
  // ─────────────────────────────────────────────────────────────

  static String coinDetails(String coinId) {
    return '$dashboardBaseUrl/coins/$coinId';
  }

  static String coinAiAnalysis(String coinId) {
    return '$aiBaseUrl/analysis/$coinId';
  }

  static String coinOhlc(String coinId) {
    return '$dashboardBaseUrl/coins/$coinId/ohlc';
  }

  // ─────────────────────────────────────────────────────────────
  // Query Helpers
  // ─────────────────────────────────────────────────────────────

  static String dashboardSummaryWithParams({
    String coinIds = 'bitcoin,ethereum,solana,binancecoin',
    String symbols = 'BTCUSDT,ETHUSDT,SOLUSDT,BNBUSDT',
  }) {
    return '$dashboardSummary?coinIds=$coinIds&symbols=$symbols';
  }

  static String marketCoinsWithParams({
    String? ids,
    String vsCurrency = 'usd',
    int perPage = 20,
    int page = 1,
    bool sparkline = true,
  }) {
    final query = <String, String>{
      if (ids != null && ids.isNotEmpty) 'ids': ids,
      'vsCurrency': vsCurrency,
      'perPage': perPage.toString(),
      'page': page.toString(),
      'sparkline': sparkline.toString(),
    };

    return Uri.parse(marketCoins).replace(queryParameters: query).toString();
  }

  static String marketCoinsSearch({
    String searchQuery = '',
    int perPage = 10,
    int page = 1,
  }) {
    final params = <String, String>{
      'perPage': perPage.toString(),
      'page': page.toString(),
      if (searchQuery.isNotEmpty) 'query': searchQuery,
    };
    return Uri.parse(marketCoins).replace(queryParameters: params).toString();
  }

  static String klinesWithParams({
    required String symbol,
    String interval = '1h',
    int limit = 100,
  }) {
    return Uri.parse(klines).replace(
      queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'limit': limit.toString(),
      },
    ).toString();
  }

  static String orderBookWithParams({
    required String symbol,
    int limit = 50,
  }) {
    return Uri.parse(orderBook).replace(
      queryParameters: {
        'symbol': symbol,
        'limit': limit.toString(),
      },
    ).toString();
  }

  static String ticker24hrWithParams({
    String? symbol,
  }) {
    return Uri.parse(ticker24hr).replace(
      queryParameters: {
        if (symbol != null && symbol.isNotEmpty) 'symbol': symbol,
      },
    ).toString();
  }

  static String exchangeInfoWithParams({
    String? symbol,
  }) {
    return Uri.parse(exchangeInfo).replace(
      queryParameters: {
        if (symbol != null && symbol.isNotEmpty) 'symbol': symbol,
      },
    ).toString();
  }

  static String fundingRatesWithSymbol({
    required String symbol,
    int limit = 10,
  }) {
    return Uri.parse(fundingRates).replace(
      queryParameters: {
        'symbol': symbol,
        'limit': limit.toString(),
      },
    ).toString();
  }

  static String fundingRatesWithSymbols({
    required List<String> symbols,
  }) {
    return Uri.parse(fundingRates).replace(
      queryParameters: {
        'symbols': symbols.join(','),
      },
    ).toString();
  }

  static String fearGreedWithParams({
    int limit = 30,
  }) {
    return Uri.parse(fearGreedIndex).replace(
      queryParameters: {
        'limit': limit.toString(),
      },
    ).toString();
  }

  static String coinOhlcWithParams({
    required String coinId,
    String vsCurrency = 'usd',
    int days = 1,
  }) {
    return Uri.parse(coinOhlc(coinId)).replace(
      queryParameters: {
        'vsCurrency': vsCurrency,
        'days': days.toString(),
      },
    ).toString();
  }

  static String newListingsWithParams({int page = 1, int limit = 20}) {
    return Uri.parse(newListings).replace(
      queryParameters: {'page': '$page', 'limit': '$limit'},
    ).toString();
  }

  static String analysisIndicatorsWithParams({
    required String symbol,
    required String type,
    String interval = '1h',
  }) {
    return Uri.parse(analysisIndicators).replace(
      queryParameters: {'symbol': symbol, 'type': type, 'interval': interval},
    ).toString();
  }

  static String journalEntry(String id) => '$journal/$id';

  static String alertEntry(String id) => '$alerts/$id';

  static String portfolioHolding(String id) => '$portfolioHoldings/$id';

  // ─────────────────────────────────────────────────────────────
  // Token Unlocks
  // ─────────────────────────────────────────────────────────────
  static const String tokenUnlocks = '$apiBaseUrl/token-unlocks';
  static const String tokenUnlocksUpcoming =
      '$apiBaseUrl/token-unlocks/upcoming';
  static String tokenUnlocksWithParams({int page = 1, int limit = 20}) =>
      Uri.parse(tokenUnlocks).replace(
          queryParameters: {'page': '$page', 'limit': '$limit'}).toString();
  static String tokenUnlocksUpcomingWithParams({int days = 30}) =>
      Uri.parse(tokenUnlocksUpcoming)
          .replace(queryParameters: {'days': '$days'}).toString();

  // ─────────────────────────────────────────────────────────────
  // Market Memory
  // ─────────────────────────────────────────────────────────────
  static const String memoryPatterns = '$apiBaseUrl/memory/patterns';
  static const String memorySimilarEvents = '$apiBaseUrl/memory/similar-events';
  static const String memoryMarketCycles = '$apiBaseUrl/memory/market-cycles';
  static const String memoryMacroContext = '$apiBaseUrl/memory/macro-context';
  static String memoryPatternsWithParams(
          {String symbol = 'BTC', int lookback = 365}) =>
      Uri.parse(memoryPatterns).replace(queryParameters: {
        'symbol': symbol,
        'lookback': '$lookback'
      }).toString();
  static String memorySimilarEventsWithParams(
          {String symbol = 'BTC', int limit = 5}) =>
      Uri.parse(memorySimilarEvents).replace(
          queryParameters: {'symbol': symbol, 'limit': '$limit'}).toString();
  static String memoryMarketCyclesWithParams({String symbol = 'BTC'}) =>
      Uri.parse(memoryMarketCycles)
          .replace(queryParameters: {'symbol': symbol}).toString();

  // ─────────────────────────────────────────────────────────────
  // Risk Management
  // ─────────────────────────────────────────────────────────────
  static const String riskPositionSize = '$baseUrl/api/risk/position-size';
  static const String riskRrCalculator = '$baseUrl/api/risk/rr-calculator';
  static String riskMaxDrawdown({
    String symbol = 'BTCUSDT',
    String period = '30d',
    String interval = '1d',
  }) =>
      '$baseUrl/api/risk/max-drawdown?symbol=$symbol&period=$period&interval=$interval';
}
