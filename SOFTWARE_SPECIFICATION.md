# Coinastra — Software Specification Document

**Version:** 1.1.0
**Date:** 2026-05-25
**Product:** Coinastra (coisastra-main.vercel.app)
**Status:** Frontend + Backend integration complete | Live on Vercel

---

## TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Next.js Application — Marketing & Auth Layer](#3-nextjs-application--marketing--auth-layer)
4. [Flutter Web Application — Dashboard](#4-flutter-web-application--dashboard)
5. [Backend API Specification](#5-backend-api-specification)
6. [AI & RAG Infrastructure](#6-ai--rag-infrastructure)
7. [Database Design](#7-database-design)
8. [Real-Time Infrastructure](#8-real-time-infrastructure)
9. [Third-Party Integrations](#9-third-party-integrations)
10. [Authentication & Security](#10-authentication--security)
11. [Subscription & Billing](#11-subscription--billing)
12. [Background Jobs](#12-background-jobs)
13. [Deployment & DevOps](#13-deployment--devops)
14. [Design System](#14-design-system)
15. [Environment Variables](#15-environment-variables)
16. [Development Roadmap](#16-development-roadmap)
17. [Project Metrics](#17-project-metrics)

---

## 1. PROJECT OVERVIEW

### 1.1 Product Description

Coinastra is an AI-powered crypto trading intelligence platform. It gives traders real-time market analysis, RAG-powered historical pattern matching (Market Memory), sentiment aggregation across social and on-chain sources, risk management tools, a psychology-aware trade journal, and a conversational AI assistant — all inside a unified dashboard.

### 1.2 Core Value Propositions

| Feature | Description |
|---------|-------------|
| **Market Memory Engine** | RAG pipeline that matches current market structure to historical patterns and shows what happened next |
| **AI Market Analysis** | Claude/GPT-4 powered per-coin analysis with trend, support/resistance, confidence scores |
| **On-Chain Analytics** | Exchange flows, netflow charts, token unlocks calendar, and per-coin on-chain indicators |
| **Sentiment Intelligence** | Aggregated bullish/bearish score from News, Twitter, Reddit, and whale on-chain data |
| **Trade Now** | Real-time signal, open interest, long/short ratio, and liquidation heatmap for active trading |
| **Risk Management** | Interactive position sizing calculator with AI warnings |
| **Trade Journal** | Psychology-aware trade logging with AI pattern detection (FOMO, revenge trading) |
| **AI Chat Assistant** | Conversational interface with portfolio-aware context injection |
| **Predictions Leaderboard** | Community vs. AI prediction accuracy tracking |

### 1.3 Target Users

- **Retail Crypto Traders** — active traders who want data-driven edge
- **DeFi Participants** — users tracking new listings and on-chain activity
- **Institutional Desks** (Institutional tier) — teams needing API access + white-label

### 1.4 Subscription Tiers

| Tier | Price | Key Limits |
|------|-------|------------|
| **Starter** | Free | 3 AI summaries/day, 2 watchlist coins |
| **Pro** | $49/mo ($39/mo annual) | Unlimited analysis, full feature access |
| **Institutional** | $199/mo ($159/mo annual) | 5 seats, API access, white-label, SLA |

---

## 2. SYSTEM ARCHITECTURE

### 2.1 High-Level Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                    coisastra-main.vercel.app                   │
├──────────────────────────┬────────────────────────────────────┤
│   Next.js (/)            │   Flutter Web (/app/)              │
│   Landing + Auth         │   Authenticated Dashboard          │
└──────────────────────────┴────────────────────────────────────┘
                           │
              HTTPS + Socket.IO
                           │
          ┌────────────────┴────────────────┐
          │   crypto-backend-4557.onrender.com │
          │   REST API (/api/v1/*)            │
          │   WebSocket (Socket.IO)           │
          │   WebSocket Cache (Binance data)  │
          └────────────────┬────────────────┘
                           │
   ┌──────┬───────────────┴──────────────────────┐
   │      │                                       │
   ▼      ▼                       ▼               ▼
PostgreSQL  Redis             pgvector        External APIs
(users,   (sessions,         (RAG vector     (CoinGecko,
 trades,   cache, queues)     embeddings)     Alternative.me,
 journal)                                     Binance WS cache)
```

### 2.2 URL Routing Architecture

**Development:**
```
Next.js:   npm run dev → http://localhost:3000
Flutter:   flutter run -d web-server --web-port 5001 --dart-define=ENV=dev
Backend:   http://localhost:8080 (Flutter uses --dart-define=ENV=dev)

Next.js rewrites (dev, next.config.mjs):
  /app, /app/* → proxy to Flutter on :5001
```

**Production (Vercel — single URL):**
```
https://coisastra-main.vercel.app
├── /app             → Flutter Web (embedded in Next.js public/app/)
├── /app/            → Flutter Web index.html
├── /app/:path*      → Flutter Web index.html (client-side routing)
└── /*               → Next.js (landing, auth, blog, pricing)

Backend API + WebSocket:
  https://crypto-backend-4557.onrender.com  (Render.com)
```

### 2.3 Technology Stack Summary

| Layer | Technology |
|-------|------------|
| Marketing / Auth Frontend | Next.js 14.2.5, React 18.3.1, TypeScript, Tailwind CSS |
| Dashboard Frontend | Flutter 3.3+, Dart, Riverpod, GoRouter |
| Backend API | Node.js (live on Render) |
| Primary Database | PostgreSQL 16 + pgvector extension |
| Cache / Sessions | Redis 7 (Upstash managed) |
| Vector Store | pgvector (co-located) |
| Background Jobs | BullMQ (Redis-backed) |
| LLM | Anthropic Claude Sonnet 4.6 (primary), GPT-4o (fallback) |
| Embeddings | OpenAI text-embedding-3-large |
| Hosting | Vercel (both apps, single URL) + Render (backend) |
| CI/CD | GitHub Actions |
| Real-Time Data | Socket.IO + Binance WebSocket Cache |

---

## 3. NEXT.JS APPLICATION — MARKETING & AUTH LAYER

### 3.1 Technology Stack

```
Next.js         14.2.5
React           18.3.1
TypeScript      5.5.3
Tailwind CSS    3.4.6
Framer Motion   11.3.8
Recharts        2.12.7
Radix UI        (Accordion, Dialog, Tabs, Tooltip)
Lucide React    0.400.0
Next Themes     0.3.0
React Type Animation  3.2.0
React CountUp   6.5.3
React Intersection Observer  9.13.0
Sharp           0.33.4  (image optimization)
```

### 3.2 Directory Structure

```
nextjs-app/
├── app/
│   ├── layout.tsx                  Root layout — fonts, metadata, providers
│   ├── page.tsx                    Landing page (assembles all landing components)
│   ├── not-found.tsx               Custom 404 page
│   ├── robots.ts                   SEO robots.txt generation
│   ├── sitemap.ts                  SEO sitemap generation
│   ├── blog/
│   │   └── page.tsx                Blog listing (6 articles, featured + grid)
│   └── auth/
│       ├── login/page.tsx          Email/password + Google OAuth login
│       ├── signup/page.tsx         Account creation with live password validation
│       ├── verify-otp/page.tsx     6-digit OTP verification screen
│       └── forgot-password/page.tsx  Email reset → confirmation state machine
├── components/
│   ├── auth/
│   │   ├── AuthLayout.tsx          Auth page wrapper (logo, branding, card)
│   │   ├── LoginForm.tsx           Login form component
│   │   ├── SignupForm.tsx          Signup form with validation indicators
│   │   └── ForgotPasswordForm.tsx  Forgot password with 3-state flow
│   └── landing/
│       ├── Navbar.tsx              Fixed header, mobile menu, CTAs
│       ├── Hero.tsx                Headline, ticker tape, AI analysis card
│       ├── Features.tsx            9 feature cards (3×3 grid)
│       ├── PatternEngine.tsx       Market Memory RAG demo section
│       ├── SentimentDemo.tsx       Sentiment meter + source breakdown
│       ├── RiskDemo.tsx            Interactive risk calculator demo
│       ├── Testimonials.tsx        6 user testimonials
│       ├── Pricing.tsx             3 pricing tiers with monthly/annual toggle
│       ├── FAQ.tsx                 Expandable accordion FAQ
│       ├── BlogPreview.tsx         Featured + grid blog post preview
│       ├── CTASection.tsx          Final conversion section
│       └── Footer.tsx              Links, legal, copyright
├── lib/
│   └── auth.ts                     NextAuth config — JWT, Google OAuth, token storage
├── next.config.mjs                 Rewrites (prod: /app/* → Flutter; dev: proxy :5001)
├── tailwind.config.ts
├── tsconfig.json
├── postcss.config.mjs
├── package.json
├── .env.development                Dev environment variables
└── .env.production                 Production environment variables
```

### 3.3 Pages & Routes

| Route | Purpose | Auth Required | SEO Indexed |
|-------|---------|--------------|-------------|
| `/` | Full landing page | No | Yes |
| `/blog` | Blog listing (6 articles) | No | Yes |
| `/auth/login` | Login | No | No |
| `/auth/signup` | Registration | No | No |
| `/auth/verify-otp` | OTP verification | No | No |
| `/auth/forgot-password` | Password reset | No | No |
| `/404` | Custom error page | No | No |
| `/app` | Flutter Dashboard (root) | Yes | No |
| `/app/*` | Flutter Dashboard (all routes) | Yes | No |

### 3.4 Next.js Configuration (next.config.mjs)

```js
// No "output: standalone" — Vercel handles Next.js natively
optimizePackageImports: ["lucide-react", "framer-motion"]
remotePatterns:        assets.coingecko.com, cryptologos.cc, coin-images.coingecko.com

rewrites (production):
  /app         → /app/index.html   (Flutter entry)
  /app/        → /app/index.html
  /app/:path*  → /app/index.html   (Flutter client-side routing)

rewrites (development):
  /app/:path*  → http://localhost:5001/:path*  (proxy to Flutter dev server)

headers: X-Frame-Options: DENY
         X-Content-Type-Options: nosniff
         Referrer-Policy: strict-origin-when-cross-origin
```

### 3.5 Landing Page Components — Detail

#### Navbar
- Fixed/sticky header with scroll-based styling change
- Logo with gradient icon + "Coin**astra**" text
- Desktop nav links: Features, Market Memory, Pricing, Blog
- Desktop CTAs: "Log in" (ghost), "Dashboard" → `/app/` (outline), "Start Free" (green filled)
- Mobile: hamburger → full-screen mobile menu
- Breakpoint: `md` (768px)

#### Hero
- Animated ticker tape: 8 crypto symbols scrolling horizontally (30s loop)
- Main headline with gradient text effect
- Subheading value proposition
- 3 CTAs: "Start Free Trial", "Open Dashboard" → `/app/`, "Watch Demo"
- Live AI Market Summary card with typewriter animation
- Two-card grid:
  - Left (2/3 width): AI analysis card (sentiment score, confidence bar, trend direction)
  - Right (1/3 width): BTC price card + Fear & Greed gauge
- Live BTC price fetched from backend; null-safe (`?? 0` guards on all numeric fields)

#### Features (9 Cards)
| # | Feature | Color | Icon |
|---|---------|-------|------|
| 1 | AI Market Analysis | Green | Brain/chart |
| 2 | Market Memory Engine | Purple | Database |
| 3 | New Listings Intel | Cyan | Sparkles |
| 4 | Risk Management | Amber | Shield |
| 5 | Sentiment Intelligence | Blue | Activity |
| 6 | AI Trade Journal | Pink | BookOpen |
| 7 | Advanced Charts | Green | CandlestickChart |
| 8 | Smart Alert Center | Orange | Bell |
| 9 | AI Chat Assistant | Purple | MessageSquare |

#### PatternEngine (Market Memory Demo)
- Left column: headline, 4 benefit bullets, "Explore Patterns" CTA
- Right column:
  - Current market state card (live parameters)
  - 3 historical pattern match cards, each showing:
    - Date range of historical period
    - Similarity percentage + progress bar
    - Outcome (% move that followed)
    - Key contributing factors (badge chips)

#### SentimentDemo
- Overall bullish score gauge (0–100)
- Source breakdown table: Twitter %, Reddit %, Whale Activity %
- News feed: 4 items with Bullish / Bearish / Neutral badges

#### RiskDemo (Interactive)
- Sliders: Account Capital ($1K–$100K), Leverage (1x–20x), Risk Per Trade (0.5%–10%)
- Outputs update live: Position Size, Liquidation Distance %
- Leverage color coding: green ≤3x, amber 4–7x, red ≥8x
- AI warning box displayed when leverage ≥ 8x
- Risk label: Conservative / Moderate / High Risk

#### Pricing (3 Tiers)
- Monthly / Annual toggle (annual = ~20% discount)
- **Starter** (Free): 3 AI summaries/day, basic sentiment, F&G, 2 coins, Discord
- **Pro** ($49/$39): Everything unlimited, all features, real-time WS, priority support
- **Institutional** ($199/$159): Everything + 5 seats, API access, white-label, SLA

---

## 4. FLUTTER WEB APPLICATION — DASHBOARD

### 4.1 Technology Stack

```
Flutter SDK       >=3.3.0 <4.0.0
Dart              3.3+
go_router         ^14.2.0    Navigation
flutter_riverpod  ^2.5.1     State management
riverpod_annotation ^2.3.5   Code generation
google_fonts      ^6.2.1     Typography
flutter_animate   ^4.5.0     Animations
dio               ^5.4.3     HTTP client
retrofit          ^4.1.0     REST API generator
web_socket_channel ^3.0.1    WebSocket
hive_flutter      ^1.1.0     Local database
flutter_secure_storage ^9.2.2  JWT storage
shared_preferences ^2.3.0   Preferences
fl_chart          ^0.68.0    Charts
percent_indicator ^4.2.3     Gauges/progress
shimmer           ^3.0.0     Skeleton loaders
lottie            ^3.1.2     Lottie animations
cached_network_image ^3.3.1  Image caching
freezed_annotation ^2.4.4   Immutable models
json_annotation   ^4.9.0    JSON serialization
```

**Build for production:**
```bash
flutter build web --release --web-renderer canvaskit --base-href /app/
# Output: build/web/ → copy to nextjs-app/public/app/
```

**Dev run:**
```bash
flutter run -d web-server --web-port 5001 --dart-define=ENV=dev
```

### 4.2 Directory Structure

```
flutter-app/
├── lib/
│   ├── main.dart                           App entry point
│   ├── app/
│   │   ├── app.dart                        Root MaterialApp + ThemeData
│   │   └── router.dart                     GoRouter — 16 routes in ShellRoute
│   ├── core/
│   │   ├── end_points.dart                 All API endpoints (env-aware baseUrl)
│   │   ├── remote/
│   │   │   ├── api_client.dart             Dio HTTP client (JWT interceptor)
│   │   │   ├── web_socket_baseclass.dart   Socket.IO client (DashboardSocket singleton)
│   │   │   ├── chat_socket.dart            Chat WebSocket
│   │   │   └── data/
│   │   │       ├── dashboard/              DashboardRepo + DashboardRepoImpl + models
│   │   │       ├── analysis/               AnalysisRepo + models
│   │   │       ├── new_listings/           NewListingsRepo + models
│   │   │       ├── orderbook/              OrderbookRepo + models
│   │   │       ├── predictions/            PredictionsRepo + models
│   │   │       ├── sentiment/              Sentiment models
│   │   │       ├── trade_now/              TradeNowRepo + models
│   │   │       └── journal/               Journal models
│   │   ├── theme/
│   │   │   ├── app_colors.dart             All color constants (AppColors class)
│   │   │   └── app_theme.dart              Full ThemeData, TextThemes, InputDecoration
│   │   └── widgets/
│   │       ├── app_shell.dart              Responsive layout (sidebar + topbar + content)
│   │       ├── sidebar.dart                Desktop navigation sidebar (220px)
│   │       ├── top_bar.dart                Top header (60px) with live indicator + coin search
│   │       ├── coin_selector.dart          Reusable coin search/select widget
│   │       └── glass_card.dart             Reusable glass-morphism card widget
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── widgets/
│   │   │       ├── market_overview_card.dart   4-coin live price cards (WebSocket)
│   │   │       ├── ai_summary_card.dart        LLM-generated market insight
│   │   │       ├── fear_greed_widget.dart       Fear & Greed gauge
│   │   │       ├── funding_rate_panel.dart      5-coin funding rates + "View All" (100 coins)
│   │   │       ├── portfolio_overview.dart      User holdings summary
│   │   │       ├── trending_coins.dart          CoinGecko trending list
│   │   │       └── whale_alerts.dart            Live whale alerts (WebSocket)
│   │   ├── ai_analysis/
│   │   │   └── ai_analysis_screen.dart         Per-coin AI analysis with coin selector
│   │   ├── charts/
│   │   │   └── charts_screen.dart              Candlestick chart with indicators
│   │   ├── market_memory/
│   │   │   └── market_memory_screen.dart       RAG pattern matching (any coin search)
│   │   ├── news_sentiment/
│   │   │   └── news_sentiment_screen.dart      News + social sentiment tabs
│   │   ├── new_listings/
│   │   │   └── new_listings_screen.dart        New coin listings with AI scores
│   │   ├── onchain/
│   │   │   └── onchain_screen.dart             On-chain analytics (4 tabs: indicators,
│   │   │                                        exchange flows, netflow chart, token unlocks)
│   │   ├── token_unlocks/
│   │   │   └── token_unlocks_screen.dart       Token unlock schedule + calendar
│   │   ├── orderbook/
│   │   │   └── orderbook_screen.dart           Live order book depth
│   │   ├── trade_now/
│   │   │   └── trade_now_screen.dart           Trade signal + open interest + long/short
│   │   ├── portfolio/
│   │   │   └── portfolio_screen.dart           User portfolio (auth-required)
│   │   ├── predictions/
│   │   │   └── predictions_leaderboard_screen.dart  Community vs. AI predictions
│   │   ├── risk_management/
│   │   │   └── risk_management_screen.dart
│   │   ├── trade_journal/
│   │   │   └── trade_journal_screen.dart       (auth-required)
│   │   ├── ai_chat/
│   │   │   └── ai_chat_screen.dart
│   │   ├── alerts/
│   │   │   └── alerts_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart             (auth-required)
│   ├── providers/
│   │   ├── auth_provider.dart              JWT auth state (coinastra_* localStorage keys)
│   │   ├── dashboard_provider.dart         Market data + Socket.IO stream providers
│   │   ├── ai_analysis_provider.dart       Per-coin AI analysis
│   │   ├── ai_chat_provider.dart           Chat message state
│   │   ├── ai_summary_provider.dart        AI market summary
│   │   ├── alerts_provider.dart            Alert CRUD
│   │   ├── analysis_provider.dart          Trade analysis (signal, OI, L/S, liq)
│   │   ├── charts_provider.dart            OHLCV candles + indicators
│   │   ├── exchange_flows_provider.dart    Exchange flows netflow + breakdown
│   │   ├── journal_provider.dart           Trade journal CRUD
│   │   ├── market_memory_provider.dart     RAG pattern search (any coin)
│   │   ├── new_listings_provider.dart      New coin listings
│   │   ├── onchain_indicators_provider.dart  Per-coin on-chain metrics (level-colored)
│   │   ├── orderbook_provider.dart         Live order book
│   │   ├── portfolio_provider.dart         Portfolio holdings
│   │   ├── predictions_provider.dart       Prediction leaderboard + accuracy
│   │   ├── profile_provider.dart           User profile data
│   │   ├── risk_provider.dart              Risk calculator
│   │   ├── sentiment_provider.dart         News + social sentiment
│   │   ├── token_unlocks_provider.dart     Token unlock schedule
│   │   └── trade_now_provider.dart         Real-time trade signals
│   └── services/
│       ├── pref_keys.dart                  SharedPreferences key constants (coinastra_*)
│       └── shared_pref_services.dart       Preference read/write helpers
├── web/
│   └── index.html                          <base href="$FLUTTER_BASE_HREF"> (Vercel /app/)
├── assets/
│   ├── fonts/       Inter + JetBrains Mono (8 weights total)
│   ├── images/
│   └── animations/  Lottie JSON files
├── pubspec.yaml
└── analysis_options.yaml
```

### 4.3 Navigation Architecture

**GoRouter — ShellRoute wraps all 16 routes:**

```dart
ShellRoute(
  builder: (ctx, state, child) => AppShell(child: child),
  routes: [
    /dashboard        → DashboardScreen
    /analysis         → AiAnalysisScreen
    /charts           → ChartsScreen
    /memory           → MarketMemoryScreen
    /sentiment        → NewsSentimentScreen
    /listings         → NewListingsScreen
    /orderbook        → OrderbookScreen
    /onchain          → OnchainScreen
    /token-unlocks    → TokenUnlocksScreen
    /trade-now        → TradeNowScreen (accepts ?coin= query param)
    /portfolio        → PortfolioScreen  [auth-required]
    /risk             → RiskManagementScreen
    /journal          → TradeJournalScreen  [auth-required]
    /chat             → AiChatScreen
    /profile          → ProfileScreen  [auth-required]
    /predictions      → PredictionsLeaderboardScreen
  ]
)
```

**Auth guard:** `_AuthGuardedPage` wraps auth-required screens. If not logged in, shows a sign-in prompt card with a link to `/auth/login` (Next.js) via `html.window.location.assign`. The user can dismiss and continue browsing public screens.

**AppShell Responsive Breakpoints:**

| Screen Width | Layout |
|-------------|--------|
| ≥ 1024px (Desktop) | Sidebar (220px) + TopBar (60px) + Scrollable Content |
| 768–1023px (Tablet) | TopBar + Content + BottomNavigationBar (5 tabs) |
| < 768px (Mobile) | TopBar + Content + BottomNavigationBar (5 tabs) |

### 4.4 Sidebar Navigation Groups

```
OVERVIEW
  └── Dashboard

AI INTELLIGENCE
  ├── AI Analysis
  ├── Market Memory
  └── AI Chat

MARKET
  ├── Charts
  ├── Order Book
  ├── Sentiment
  └── New Listings  [badge: HOT]

ON-CHAIN
  ├── On-Chain Analytics
  └── Token Unlocks

TRADING
  ├── Trade Now
  ├── Risk Manager
  ├── Trade Journal
  ├── Portfolio
  ├── Predictions
  └── Alerts        [badge: unread count]

ACCOUNT
  └── Profile
```

### 4.5 Environment / Config

**Base URL switching (single variable):**
```dart
// flutter-app/lib/core/end_points.dart
static const String _env = String.fromEnvironment('ENV', defaultValue: 'prod');
static const String baseUrl = _env == 'dev'
    ? 'http://localhost:8080'
    : 'https://crypto-backend-4557.onrender.com';
static const String socketUrl = baseUrl;  // Socket.IO always follows baseUrl
```

**Run dev:** `flutter run -d web-server --web-port 5001 --dart-define=ENV=dev`
**Build prod:** `flutter build web --release --web-renderer canvaskit --base-href /app/`

### 4.6 Screen-by-Screen Specification

---

#### Screen 1: Dashboard (`/dashboard`)

**Purpose:** Home screen — overview of market, portfolio, AI insights.

**Widgets:**
| Widget | Data Source | Update Frequency |
|--------|------------|-----------------|
| MarketOverviewCard (×4) | BTC, ETH, SOL, BNB prices + 24h change | WebSocket (real-time) |
| AiSummaryCard | LLM-generated insight (`/dashboard/trade-analysis`) | 15 min |
| FearGreedWidget | Alternative.me via backend | 1 h |
| FundingRatePanel | 5 coins (BTC/ETH/SOL/BNB/XRP) + "View All" 100 coins | 30 s |
| PortfolioOverview | User's holdings + live prices | 60 s |
| TrendingCoins | CoinGecko trending endpoint | 5 min |
| WhaleAlerts | Socket.IO `whaleStream` | Real-time push |

**Funding Rate "View All":**
- Opens a bottom sheet with all 100 coins (`allFundingRatesProvider`)
- Live search filters locally across all 100 symbols
- Sorted by absolute funding rate descending

---

#### Screen 2: AI Analysis (`/analysis`)

**Purpose:** Deep AI analysis for a selected coin.

**UI Sections:**
- Coin selector (default: BTC, searchable)
- MarketSummaryCard — LLM narrative: trend, momentum, key events, confidence %
- SupportResistanceCard — S1, S2, R1, R2, Pivot
- SentimentCard — bullish % breakdown by source
- VolatilityCard — ATR (14), Bollinger Band width
- KeyLevelsCard — formatted table of price levels

**Endpoint:** `GET /api/v1/dashboard/trade-analysis?symbol=BTC`
**Caching:** 15 min per (coinId, analysis)

---

#### Screen 3: Charts (`/charts`)

**Purpose:** Advanced charting interface.

**Features:**
- Timeframe selector: `1m | 5m | 15m | 1H | 4H | 1D | 1W`
- Coin selector
- Indicator toggles: RSI, MACD, EMA (9, 21, 50), Volume, Bollinger Bands
- Candlestick chart rendered via `fl_chart`
- Indicator panel below chart showing numeric values

**Endpoints:**
- `GET /api/v1/dashboard/klines?symbol=BTCUSDT&interval=1h&limit=100`
- `GET /api/v1/analysis/indicators?symbol=BTCUSDT&type=rsi&interval=1h`

---

#### Screen 4: Market Memory (`/memory`)

**Purpose:** RAG-powered historical pattern matching.

**UI:**
- **Coin selector:** Search any coin (not limited to BTC/ETH/SOL pills)
- **Current State Card:** Shows live market parameters
- **Pattern Match Cards (×4):** Ordered by similarity score
  - Historical date range, similarity %, outcome %, key factors

**Endpoints:**
- `GET /api/v1/memory/patterns?symbol=BTC&lookback=365`
- `GET /api/v1/memory/similar-events?symbol=BTC&limit=5`
- `GET /api/v1/memory/market-cycles?symbol=BTC`
- `GET /api/v1/memory/macro-context`

---

#### Screen 5: News & Sentiment (`/sentiment`)

**Purpose:** Aggregated sentiment from all sources.

**Tabs:** News | Twitter | Reddit | Whale Activity

**Endpoints:**
- `GET /api/sentiment/news`
- `GET /api/sentiment/social`
- `GET /api/sentiment/coins/:coinId`

---

#### Screen 6: New Listings (`/listings`)

**Purpose:** Early detection of new coin listings with AI scoring.

**Filter Tabs:** All | AI | Meme | DeFi | Gaming | RWA

**Per Listing Card:**
- Symbol + name, price + 24h change
- Momentum (0–100), Potential (0–100), Risk (Low/Medium/High)
- Volume surge multiplier, whale/smart-money tags, AI reason

**Endpoint:** `GET /api/v1/dashboard/new-listings?page=1&limit=20`

---

#### Screen 7: On-Chain Analytics (`/onchain`)

**Purpose:** On-chain data organized in 4 tabs for a selected coin.

**Coin selector:** Defaults to BTC, switchable — top exchanges and indicators update per coin.

**Tabs:**
1. **Indicators** — Per-coin on-chain metrics (NVT, SOPR, MVRV, exchange netflow, active addresses, etc.)
   - Each indicator card shows: name, value, signal text, description
   - Color-coded by `level`: bullish (green), neutral (amber), bearish (red)
   - Endpoint: `GET /api/v1/onchain/indicators?symbol=BTC`

2. **Exchange Flows** — Top exchanges breakdown (inflows vs. outflows per exchange)
   - Data comes from `exchangeFlowsNetflowProvider(symbol)` → `flow.exchangeBreakdown`
   - Updates when coin selector changes
   - Endpoint: `GET /api/v1/exchange-flows/netflow?symbol=BTC&days=30`

3. **Netflow Chart** — 30-day exchange netflow area chart for selected coin
   - Positive = net inflow (selling pressure), negative = net outflow (accumulation)

4. **Token Unlocks** — Upcoming unlocks for selected coin
   - Endpoint: `GET /api/v1/token-unlocks?page=1&limit=20`

---

#### Screen 8: Token Unlocks (`/token-unlocks`)

**Purpose:** Upcoming token unlock schedule with calendar view.

**Sections:**
- Summary stats: Total unlocking in 30d, largest upcoming unlock
- List view: project name, unlock date, amount, % of supply, category (team/investor/ecosystem)
- Upcoming unlocks filter (next 7d / 30d / 90d)

**Endpoints:**
- `GET /api/v1/token-unlocks?page=1&limit=20`
- `GET /api/v1/token-unlocks/upcoming?days=30`

---

#### Screen 9: Order Book (`/orderbook`)

**Purpose:** Live order book depth visualization.

**Features:**
- Symbol selector
- Bid/Ask depth table (top 50 levels each side)
- Cumulative depth bars
- Real-time updates

**Endpoint:** `GET /api/v1/dashboard/order-book?symbol=BTCUSDT&limit=50`

---

#### Screen 10: Trade Now (`/trade-now`)

**Purpose:** Real-time signals and market microstructure for active trading.

**Accepts:** `?coin=BTCUSDT` query parameter (linkable from other screens)

**Tabs:**
1. **Signal** — Buy/Sell/Hold signal with confidence %, key reasons
2. **Open Interest** — OI trend chart, long/short ratio
3. **Liquidations** — Liquidation heatmap
4. **History** — Recent signal history for coin

**Endpoints:**
- `GET /api/v1/analysis/signal?symbol=BTCUSDT`
- `GET /api/v1/analysis/open-interest?symbol=BTCUSDT`
- `GET /api/v1/analysis/long-short?symbol=BTCUSDT`
- `GET /api/v1/analysis/liquidations?symbol=BTCUSDT`
- `GET /api/v1/analysis/history?symbol=BTCUSDT`

---

#### Screen 11: Portfolio (`/portfolio`) — Auth Required

**Purpose:** User portfolio holdings and performance.

**Endpoints:**
- `GET /api/v1/portfolio`
- `GET /api/v1/portfolio/holdings`
- `GET /api/v1/portfolio/performance`

---

#### Screen 12: Risk Management (`/risk`)

**Purpose:** Interactive position sizing and risk calculator.

**Inputs (Sliders + Fields):**
| Input | Range | Default |
|-------|-------|---------|
| Account Capital | $1,000 – $100,000 | $10,000 |
| Leverage | 1x – 20x | 1x |
| Risk Per Trade | 0.5% – 10% | 1% |
| Entry Price | Manual input | — |
| Stop-Loss Price | Manual input | — |

**Outputs (Computed Live):**
| Output | Formula |
|--------|---------|
| Position Size | (Capital × Risk%) / (Entry − StopLoss) |
| Liquidation Price | Entry × (1 − 1/Leverage) |
| Liquidation Distance | (Entry − Liq) / Entry × 100 |
| Max Loss in USD | Capital × Risk% |
| Risk Level | Conservative ≤2%, Moderate ≤5%, High >5% |

**AI Warnings:** Displayed when leverage ≥ 8x

---

#### Screen 13: Trade Journal (`/journal`) — Auth Required

**Purpose:** Log trades with psychology tagging and AI pattern detection.

**Tabs:** Trades | Analytics | Psychology

---

#### Screen 14: AI Chat (`/chat`)

**Purpose:** Conversational AI assistant with trading context.

**Features:**
- Full-height chat interface with streaming responses
- 6 suggested quick-questions (BTC trend, whale activity, etc.)
- Context injected: current prices, Fear/Greed, user portfolio
- Chat history persisted per user

**Endpoint:** `POST /api/v1/ai/chat` (SSE streaming)

---

#### Screen 15: Predictions Leaderboard (`/predictions`)

**Purpose:** Community vs. AI prediction accuracy tracking.

**Tabs:** Leaderboard | My Predictions | User vs. AI

**Endpoints:**
- `GET /api/v1/predictions/leaderboard`
- `GET /api/v1/predictions/user/mine`
- `GET /api/v1/predictions/user/vs-ai`
- `GET /api/v1/predictions/:coinId/accuracy`
- `GET /api/v1/predictions/:coinId/history`

---

#### Screen 16: Profile (`/profile`) — Auth Required

**Purpose:** User account and preferences management.

**Sections:**
- ProfileCard: Avatar (initials + color), name, email, subscription tier badge
- SubscriptionCard: Current plan + usage stats + upgrade CTA
- Exchange Connections: Linked Binance / Bybit API keys
- Preferences: Dark mode toggle, notification toggles
- Security: 2FA toggle, active sessions, change password
- AI Personality: Direct | Friendly | Professional

---

## 5. BACKEND API SPECIFICATION

**Base URL:** `https://crypto-backend-4557.onrender.com`
**API Prefix:** `/api/v1`
**Authentication:** JWT Bearer token (`Authorization: Bearer <token>`)
**Format:** JSON request/response
**Real-Time:** Socket.IO on the same host

**WebSocket Cache:** Backend maintains a persistent Binance WebSocket connection and caches all market data internally. Flutter connects to the backend Socket.IO server — never directly to Binance. This avoids browser CORS and Binance API key exposure.

---

### 5.1 Implemented Dashboard Endpoints

| Method | Route | Cache TTL | Status |
|--------|-------|-----------|--------|
| GET | `/api/v1/dashboard/summary` | 60s | ✅ Live |
| GET | `/api/v1/dashboard/markets` | 60s | ✅ Live |
| GET | `/api/v1/dashboard/trending` | 5m | ✅ Live |
| GET | `/api/v1/dashboard/fear-greed` | 1h | ✅ Live |
| GET | `/api/v1/dashboard/funding-rates` | 30s | ✅ Live |
| GET | `/api/v1/dashboard/klines` | 5m | ✅ Live |
| GET | `/api/v1/dashboard/order-book` | 10s | ✅ Live |
| GET | `/api/v1/dashboard/ticker-24hr` | 30s | ✅ Live |
| GET | `/api/v1/dashboard/new-listings` | 15m | ✅ Live |
| GET | `/api/v1/dashboard/trade-analysis` | 15m | ✅ Live |

### 5.2 Implemented Analysis Endpoints

| Method | Route | Status |
|--------|-------|--------|
| GET | `/api/v1/analysis/signal` | ✅ Live |
| GET | `/api/v1/analysis/sentiment` | ✅ Live |
| GET | `/api/v1/analysis/open-interest` | ✅ Live |
| GET | `/api/v1/analysis/long-short` | ✅ Live |
| GET | `/api/v1/analysis/liquidations` | ✅ Live |
| GET | `/api/v1/analysis/history` | ✅ Live |
| GET | `/api/v1/analysis/levels` | ✅ Live |
| GET | `/api/v1/analysis/indicators` | ✅ Live |

### 5.3 Implemented On-Chain Endpoints

| Method | Route | Query Params | Status |
|--------|-------|-------------|--------|
| GET | `/api/v1/onchain/indicators` | `symbol=BTC` | ✅ Live |
| GET | `/api/v1/exchange-flows/netflow` | `symbol=BTC&days=30` | ✅ Live |
| GET | `/api/v1/exchange-flows/top-exchanges` | `limit=10` | ✅ Live |
| GET | `/api/v1/token-unlocks` | `page=1&limit=20` | ✅ Live |
| GET | `/api/v1/token-unlocks/upcoming` | `days=30` | ✅ Live |

**On-chain indicator response shape:**
```json
{
  "success": true,
  "data": {
    "symbol": "BTC",
    "indicators": [
      {
        "name": "NVT Ratio",
        "value": 42.5,
        "signal": "Neutral — healthy transaction volume",
        "level": "neutral",
        "description": "Network Value to Transactions ratio measures network efficiency"
      }
    ]
  }
}
```
`level` values: `"bullish"` | `"neutral"` | `"bearish"` — Flutter maps these to green/amber/red.

### 5.4 Implemented Market Memory Endpoints

| Method | Route | Status |
|--------|-------|--------|
| GET | `/api/v1/memory/patterns` | ✅ Live |
| GET | `/api/v1/memory/similar-events` | ✅ Live |
| GET | `/api/v1/memory/market-cycles` | ✅ Live |
| GET | `/api/v1/memory/macro-context` | ✅ Live |

### 5.5 Implemented Predictions Endpoints

| Method | Route | Status |
|--------|-------|--------|
| GET | `/api/v1/predictions/leaderboard` | ✅ Live |
| GET | `/api/v1/predictions/user` | ✅ Live |
| GET | `/api/v1/predictions/user/mine` | ✅ Live |
| GET | `/api/v1/predictions/user/vs-ai` | ✅ Live |
| GET | `/api/v1/predictions/:coinId/accuracy` | ✅ Live |
| GET | `/api/v1/predictions/:coinId/history` | ✅ Live |
| GET | `/api/v1/predictions/:coinId/post-mortems` | ✅ Live |

### 5.6 Auth Endpoints

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| POST | `/api/auth/register` | None | Register with email + password |
| POST | `/api/auth/login` | None | Login → returns `accessToken` + `refreshToken` |
| POST | `/api/auth/logout` | JWT | Invalidate refresh token |
| POST | `/api/auth/refresh` | Cookie | Exchange refresh token for new access token |
| POST | `/api/auth/forgot-password` | None | Send 6-digit OTP to email |
| POST | `/api/auth/verify-otp` | None | Verify OTP code |
| POST | `/api/auth/reset-password` | None | Set new password after OTP verified |
| GET  | `/api/auth/google` | None | Redirect to Google OAuth |
| GET  | `/api/auth/google/callback` | None | Handle Google OAuth callback |
| GET  | `/api/auth/me` | JWT | Return current user object |

### 5.7 User & Portfolio Endpoints (Planned)

| Method | Route | Auth | Status |
|--------|-------|------|--------|
| GET | `/api/v1/portfolio` | JWT | Planned |
| POST | `/api/v1/portfolio/holdings` | JWT | Planned |
| PATCH | `/api/v1/portfolio/holdings/:id` | JWT | Planned |
| DELETE | `/api/v1/portfolio/holdings/:id` | JWT | Planned |
| GET | `/api/v1/portfolio/performance` | JWT | Planned |

### 5.8 Trade Journal Endpoints (Planned)

| Method | Route | Auth | Status |
|--------|-------|------|--------|
| GET | `/api/journal` | JWT | Planned |
| POST | `/api/journal` | JWT | Planned |
| PATCH | `/api/journal/:id` | JWT | Planned |
| DELETE | `/api/journal/:id` | JWT | Planned |
| GET | `/api/journal/stats` | JWT | Planned |

### 5.9 Alerts Endpoints (Planned)

| Method | Route | Auth | Status |
|--------|-------|------|--------|
| GET | `/api/v1/alerts` | JWT | Planned |
| POST | `/api/v1/alerts` | JWT | Planned |
| PATCH | `/api/v1/alerts/:id` | JWT | Planned |
| DELETE | `/api/v1/alerts/:id` | JWT | Planned |

### 5.10 Risk Management Endpoints (Planned)

| Method | Route | Auth | Status |
|--------|-------|------|--------|
| POST | `/api/risk/position-size` | JWT | Planned |
| POST | `/api/risk/rr-calculator` | JWT | Planned |
| GET | `/api/risk/max-drawdown` | JWT | Planned |

---

## 6. AI & RAG INFRASTRUCTURE

### 6.1 AI Chat — Streaming Completions

**Endpoint:** `POST /api/v1/ai/chat`
**Protocol:** Server-Sent Events (SSE) for streaming

**System Prompt Template:**
```
You are Coinastra, an expert crypto trading AI assistant.

CURRENT MARKET DATA (updated 60s ago):
- BTC: ${{btcPrice}} ({{btcChange24h}}% 24h)
- ETH: ${{ethPrice}} ({{ethChange24h}}% 24h)
- Fear & Greed Index: {{fearGreed}}/100 ({{fearGreedLabel}})
- Overall Market Sentiment: {{sentimentScore}}/100

USER PORTFOLIO:
{{portfolioSummary}}

AI Personality: {{personality}}  // direct | friendly | professional
Respond concisely. Use markdown. Do not give financial advice.
```

**Models:**
- Primary: `claude-sonnet-4-6` (Anthropic)
- Fallback: `gpt-4o` (OpenAI)

---

### 6.2 AI Market Analysis

**Endpoint:** `GET /api/v1/dashboard/trade-analysis?symbol=BTC`
**Cache:** 15 min (Redis)

**Pipeline:**
```
1. Fetch coin OHLCV (30d), current price, volume, market cap
2. Compute: RSI(14), MACD, Bollinger Bands, EMA(9,21,50), support/resistance
3. Fetch sentiment score for coin
4. Build structured prompt with all data
5. Call Claude Sonnet → structured JSON response:
   {
     "summary": "...",
     "trendDirection": "bullish|bearish|neutral",
     "confidenceScore": 72,
     "supportLevels": [94200, 91500],
     "resistanceLevels": [98000, 102000],
     "keyRisks": ["..."],
     "outlook": "short|medium|long"
   }
6. Cache result in Redis for 15 min
```

---

### 6.3 Market Memory Engine — Full RAG Pipeline

#### Ingestion Phase (Nightly Background Job)
```
For each coin in top-100 list:
  For each window size in [30, 60, 90] days:
    For each historical window (sliding, 7-day step):
      1. Fetch OHLCV data for the window
      2. Compute feature vector (price_change_pct, rsi, macd, funding_rate_avg,
         fear_greed_avg, btc_dominance_avg, sentiment_score_avg, ...)
      3. Convert to natural language description string
      4. Call OpenAI text-embedding-3-large → 1536-dim vector
      5. Upsert into pgvector market_patterns table with outcome_data
```

#### Query Phase (On User Request)
```
1. Compute current market feature vector for requested coin
2. Convert to natural language description
3. Embed via OpenAI text-embedding-3-large
4. pgvector cosine similarity search → top 5 matches
5. Claude generates narrative for each match
6. Return: [ { date, similarity%, outcome, keyFactors, explanation } × 4 ]
```

---

### 6.4 Sentiment AI Scoring

**Pipeline:** Claude Haiku batch-classifies news/tweets as bullish/bearish/neutral.
Aggregated per coin, cached in Redis (key: `sentiment:{hash(text)}`, TTL: 24h).

---

## 7. DATABASE DESIGN

### 7.1 PostgreSQL — Tables

#### users
```sql
CREATE TABLE users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT UNIQUE NOT NULL,
  password_hash   TEXT,
  google_id       TEXT UNIQUE,
  name            TEXT,
  avatar_url      TEXT,
  plan            TEXT NOT NULL DEFAULT 'free',
  email_verified  BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);
```

#### refresh_tokens
```sql
CREATE TABLE refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT UNIQUE NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX ON refresh_tokens (user_id);
```

#### otp_codes
```sql
CREATE TABLE otp_codes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code        TEXT NOT NULL,
  purpose     TEXT NOT NULL,   -- forgot_password | email_verify
  expires_at  TIMESTAMPTZ NOT NULL,
  used        BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);
```

#### portfolio_holdings
```sql
CREATE TABLE portfolio_holdings (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  coin_id             TEXT NOT NULL,
  coin_symbol         TEXT NOT NULL,
  amount              NUMERIC(20, 8) NOT NULL,
  avg_buy_price_usd   NUMERIC(20, 8),
  created_at          TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX ON portfolio_holdings (user_id);
```

#### trade_journal
```sql
CREATE TABLE trade_journal (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pair          TEXT NOT NULL,
  direction     TEXT NOT NULL CHECK (direction IN ('long', 'short')),
  entry_price   NUMERIC(20, 8),
  exit_price    NUMERIC(20, 8),
  size          NUMERIC(20, 8),
  pnl_usd       NUMERIC(20, 8),
  pnl_percent   NUMERIC(10, 4),
  entry_at      TIMESTAMPTZ,
  exit_at       TIMESTAMPTZ,
  notes         TEXT,
  psychology    TEXT CHECK (psychology IN ('fomo', 'patient', 'revenge', 'disciplined')),
  strategy      TEXT,
  outcome       TEXT CHECK (outcome IN ('win', 'loss', 'breakeven')),
  created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX ON trade_journal (user_id, entry_at DESC);
```

#### alerts
```sql
CREATE TABLE alerts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  coin_id       TEXT NOT NULL,
  coin_symbol   TEXT NOT NULL,
  alert_type    TEXT NOT NULL,
  condition     TEXT,
  target_value  NUMERIC(20, 8),
  is_active     BOOLEAN DEFAULT true,
  fired_at      TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX ON alerts (user_id);
CREATE INDEX ON alerts (is_active, coin_id);
```

#### chat_messages
```sql
CREATE TABLE chat_messages (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content     TEXT NOT NULL,
  model       TEXT,
  tokens_used INTEGER,
  created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX ON chat_messages (user_id, created_at DESC);
```

#### user_preferences
```sql
CREATE TABLE user_preferences (
  user_id        UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  currency       TEXT DEFAULT 'USD',
  timezone       TEXT DEFAULT 'UTC',
  theme          TEXT DEFAULT 'dark',
  email_alerts   BOOLEAN DEFAULT true,
  push_alerts    BOOLEAN DEFAULT true,
  default_coins  TEXT[] DEFAULT ARRAY['bitcoin', 'ethereum'],
  ai_personality TEXT DEFAULT 'friendly',
  updated_at     TIMESTAMPTZ DEFAULT now()
);
```

#### subscriptions
```sql
CREATE TABLE subscriptions (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stripe_customer_id      TEXT UNIQUE,
  stripe_subscription_id  TEXT UNIQUE,
  plan                    TEXT NOT NULL CHECK (plan IN ('pro', 'elite')),
  status                  TEXT NOT NULL,
  current_period_end      TIMESTAMPTZ,
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX ON subscriptions (user_id);
```

---

### 7.2 pgvector — Vector Store

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE market_patterns (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coin_id         TEXT NOT NULL,
  window_start    DATE NOT NULL,
  window_end      DATE NOT NULL,
  interval_days   INTEGER NOT NULL,
  embedding       vector(1536) NOT NULL,
  features        JSONB NOT NULL,
  outcome_data    JSONB,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX ON market_patterns
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

CREATE INDEX ON market_patterns (coin_id, window_start);
```

---

### 7.3 Redis — Key Namespaces

| Key Pattern | TTL | Purpose |
|-------------|-----|---------|
| `session:{userId}` | 7d | Session data |
| `market:coins:list:{page}` | 60s | Paginated coin list |
| `market:coin:{coinId}` | 30s | Single coin data |
| `market:ohlcv:{coinId}:{interval}` | 5m | OHLCV candles |
| `market:feargreed` | 1h | Fear & Greed index |
| `market:funding` | 30s | Funding rates |
| `ai:analysis:{coinId}` | 15m | LLM analysis per coin |
| `onchain:{symbol}` | 5m | On-chain indicators per coin |
| `exchange-flows:{symbol}` | 5m | Exchange flow netflow per coin |
| `token-unlocks` | 1h | Token unlock schedule |
| `memory:{symbol}` | 30m | RAG pattern results per coin |
| `sentiment:news` | 10m | News with scores |
| `sentiment:{hash(text)}` | 24h | Individual article/tweet score |
| `rl:{userId}:{endpoint}` | sliding | Per-user rate limit counter |

---

## 8. REAL-TIME INFRASTRUCTURE

### 8.1 WebSocket Architecture

**Library:** Socket.IO (server), `socket_io_client` (Flutter)
**Connection:** `https://crypto-backend-4557.onrender.com` (same host as REST API)
**Implementation:** `DashboardSocket` singleton (`web_socket_baseclass.dart`)

**Key design:**
- Backend maintains persistent connection to Binance WebSocket streams
- Flutter connects to backend Socket.IO (never directly to Binance)
- Prevents CORS issues and exposes no API keys to browser

### 8.2 Socket.IO Event Contract

| Event (server→client) | Payload | Flutter Provider |
|----------------------|---------|-----------------|
| `market:miniTicker` | `List<TickerUpdate>` | `tickerProvider` → `Map<symbol, TickerUpdate>` |
| `whale:alert` | `List<LiveWhaleAlert>` | `liveWhaleProvider` |
| `funding:update` | `List<LiveFundingRate>` | `liveFundingProvider` |
| `connect` / `disconnect` | — | `socketConnectionProvider` |

### 8.3 Binance WebSocket Cache

The backend subscribes to Binance WebSocket streams server-side and serves cached data to Flutter clients. Env var: `BINANCE_USE_WEBSOCKET_CACHE=true`.

This replaces direct Binance REST API calls that caused CORS errors in browser-based Flutter Web.

---

## 9. THIRD-PARTY INTEGRATIONS

### 9.1 Market Data

| Provider | Endpoint Used | Rate Limit | Env Var |
|----------|--------------|------------|---------|
| **CoinGecko Pro** | `/coins/markets`, `/coins/{id}`, `/search/trending` | 500 req/min | `COINGECKO_API_KEY` |
| **Binance** | WebSocket streams (server-side cache) | N/A | `BINANCE_API_KEY` |
| **Alternative.me** | `https://api.alternative.me/fng/` | Free, cache 1h | None |

### 9.2 AI & LLM

| Service | Model | Use Case | Env Var |
|---------|-------|---------|---------|
| **Anthropic** | `claude-sonnet-4-6` | Market analysis, chat (primary) | `ANTHROPIC_API_KEY` |
| **Anthropic** | `claude-haiku-4-5-20251001` | Sentiment scoring (cheap, high-volume) | `ANTHROPIC_API_KEY` |
| **OpenAI** | `gpt-4o` | Chat fallback | `OPENAI_API_KEY` |
| **OpenAI** | `text-embedding-3-large` | RAG embeddings | `OPENAI_API_KEY` |

### 9.3 Auth, Email, Payments

| Service | Purpose | Env Var |
|---------|---------|---------|
| **Google OAuth 2.0** | Social login | `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` |
| **Resend** | Transactional email (OTP, welcome, alerts) | `RESEND_API_KEY` |
| **Stripe** | Subscription billing | `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` |

---

## 10. AUTHENTICATION & SECURITY

### 10.1 Auth Flow

```
Email/Password:
  Register → hash password (bcrypt, cost 12)
           → send verification OTP
           → verify OTP → mark email_verified = true
           → login → issue JWT (15m) + refresh token (7d, httpOnly cookie)

Google OAuth:
  Click "Continue with Google"
  → redirect to /api/auth/google → Google consent screen
  → callback → upsert user (google_id) → issue JWT + refresh token

Token Refresh:
  Access token expires → client sends refresh token (cookie)
  → server validates, issues new access token (rotation)
```

### 10.2 Storage Keys

All localStorage/SharedPreferences keys use `coinastra_` prefix:
- `coinastra_access` — JWT access token
- `coinastra_refresh` — Refresh token
- `coinastra_user` — Cached user object

### 10.3 Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| `POST /api/auth/login` | 5 attempts | 15 min per IP |
| `POST /api/auth/register` | 3 accounts | 1 hour per IP |
| `POST /api/auth/forgot-password` | 3 OTP sends | 15 min per email |
| `POST /api/ai/chat` | Free: 3/day, Pro+: unlimited | 24 hours per user |
| All other endpoints | 100 req/min | Per user (JWT) |
| Unauthenticated | 20 req/min | Per IP |

### 10.4 Security Headers

```
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

---

## 11. SUBSCRIPTION & BILLING

### 11.1 Stripe Integration

**Events handled:**
- `checkout.session.completed` → create subscription row
- `customer.subscription.updated` → update plan/status
- `customer.subscription.deleted` → downgrade to free
- `invoice.payment_failed` → mark status `past_due`, send email

### 11.2 Feature Gating

| Feature | Free | Pro | Institutional |
|---------|------|-----|--------------|
| AI Market Summaries | 3/day | Unlimited | Unlimited |
| Market Memory Engine | No | Yes | Yes |
| On-Chain Analytics | Basic | Full | Full |
| Token Unlocks | No | Yes | Yes |
| Trade Now Signals | No | Yes | Yes |
| Advanced Sentiment | Basic only | Yes | Yes |
| New Listings Intel | No | Yes | Yes |
| Risk Calculator | No | Yes | Yes |
| Trade Journal + Psychology | No | Yes | Yes |
| Whale Alerts | No | Yes | Yes |
| Advanced Charts + AI Overlay | No | Yes | Yes |
| AI Chat | No | Yes (GPT-4) | Yes (Priority) |
| Real-time WebSocket | No | Yes | Yes |
| API Access | No | No | Yes |
| Team Seats | 1 | 1 | 5 |
| White-label | No | No | Yes |
| SLA | No | No | Yes |

---

## 12. BACKGROUND JOBS

**Queue System:** BullMQ with Redis broker

| Job | Schedule | Description |
|-----|----------|-------------|
| `ingest-market-history` | Daily 00:00 UTC | Fetch OHLCV for top 100 coins, compute feature vectors, embed, upsert to pgvector |
| `score-new-listings` | Every 4h | CoinGecko new listings → run AI scoring → cache results |
| `aggregate-sentiment` | Every 15m | CryptoPanic + social sources → score with Claude Haiku → cache |
| `check-price-alerts` | Every 30s | Fetch prices → compare to active alerts → fire WebSocket events + email |
| `send-alert-emails` | On trigger | Resend email when alert fires |
| `update-fear-greed` | Every 1h | Alternative.me API → cache in Redis |
| `update-whale-alerts` | Every 2m | On-chain transaction monitoring → WebSocket broadcast |
| `clean-expired-tokens` | Daily 03:00 UTC | Delete expired OTPs and refresh tokens |
| `update-funding-rates` | Every 30s | Cache from Binance WS → WebSocket broadcast |

---

## 13. DEPLOYMENT & DEVOPS

### 13.1 Local Development

**Next.js:**
```bash
cd nextjs-app && npm run dev
# Runs on http://localhost:3000
# Auto-loads .env.development (BACKEND_URL=http://localhost:8080)
```

**Flutter:**
```bash
cd flutter-app && flutter run -d web-server --web-port 5001 \
  --web-hostname localhost --dart-define=ENV=dev
# Connects to http://localhost:8080 (local backend)
```

**Backend (if running locally):**
```bash
# Start local backend on :8080
# Set BINANCE_USE_WEBSOCKET_CACHE=true
```

### 13.2 Environment Files

**Next.js — auto-loaded by NODE_ENV:**
```
nextjs-app/.env.development   # NODE_ENV=development
nextjs-app/.env.production    # NODE_ENV=production
```

**Flutter — switched by --dart-define:**
```
--dart-define=ENV=dev   → baseUrl = http://localhost:8080
(default / omit)        → baseUrl = https://crypto-backend-4557.onrender.com
```

### 13.3 Production Deployment — Single URL (Vercel)

**Step 1 — Build Flutter:**
```bash
cd flutter-app
flutter build web --release --web-renderer canvaskit --base-href /app/
```

**Step 2 — Copy Flutter build into Next.js:**
```bash
mkdir -p ../nextjs-app/public/app
cp -r build/web/* ../nextjs-app/public/app/
```

**Step 3 — Deploy Next.js to Vercel:**
- Root directory: `nextjs-app`
- Build command: `npm run build`
- Framework: Next.js (no `output: standalone`)
- Environment variables set in Vercel dashboard

**Result:** Single URL `coisastra-main.vercel.app`
- `/` → Next.js landing + auth
- `/app/` → Flutter Web (static files served from `public/app/`)
- `/app/:path*` → Flutter Web (rewrite to `index.html` for client-side routing)

### 13.4 Backend — Render.com

- **URL:** `https://crypto-backend-4557.onrender.com`
- **Platform:** Render (Docker or Node.js service)
- **PostgreSQL:** Managed Render Postgres or Supabase
- **Redis:** Upstash (serverless, free tier)
- **Key env vars:** `BINANCE_USE_WEBSOCKET_CACHE=true`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`

### 13.5 Post-Deployment Checklist

- [x] Flutter Web built with `--base-href /app/` and `<base href="$FLUTTER_BASE_HREF">`
- [x] Flutter copied to `nextjs-app/public/app/`
- [x] Next.js deployed to Vercel (coisastra-main.vercel.app)
- [x] Backend live on Render (crypto-backend-4557.onrender.com)
- [x] WebSocket (Socket.IO) using production backend URL
- [x] `output: "standalone"` removed from next.config.mjs (causes Vercel 404)
- [x] All Next.js rewrites environment-aware (prod vs. dev)
- [ ] PostgreSQL migrations run in production
- [ ] pgvector extension enabled
- [ ] All environment variables set in Vercel + Render dashboards
- [ ] Stripe webhook endpoint registered
- [ ] Google OAuth redirect URIs updated to coisastra-main.vercel.app
- [ ] CORS configured for production backend
- [ ] Rate limiting enabled
- [ ] Sentry error tracking set up

---

## 14. DESIGN SYSTEM

### 14.1 Color Palette

**Background:**
| Token | Hex | Use |
|-------|-----|-----|
| `bg-primary` | `#0A0B0F` | Main page background |
| `bg-secondary` | `#0F1117` | Section backgrounds |
| `bg-card` | `#141720` | Card backgrounds |
| `bg-card-hover` | `#1A1D28` | Card hover state |

**Brand Colors:**
| Token | Hex | Use |
|-------|-----|-----|
| `brand-green` | `#00FF88` | Primary accent, positive, CTAs |
| `brand-green-dim` | `#00CC6A` | Secondary green, hover states |
| `brand-red` | `#FF3366` | Negative, danger, loss |
| `brand-blue` | `#3B82F6` | Info, links, secondary actions |
| `brand-purple` | `#8B5CF6` | AI features, premium |
| `brand-cyan` | `#06B6D4` | Market data, listings |
| `brand-amber` | `#F59E0B` | Warnings, risk indicators, neutral on-chain |
| `brand-pink` | `#EC4899` | Trade journal, psychology |
| `brand-orange` | `#F97316` | Alerts |

**On-Chain Level Colors:**
| Level | Color | Used In |
|-------|-------|---------|
| `bullish` | `brand-green` | On-chain indicator cards |
| `neutral` | `brand-amber` | On-chain indicator cards |
| `bearish` | `brand-red` | On-chain indicator cards |

### 14.2 Typography

**Fonts:** Inter (primary), JetBrains Mono (code/numbers)

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| Display Large | 48px | 900 | Hero headlines |
| Display Medium | 36px | 800 | Section headlines |
| Headline Large | 24px | 700 | Card titles |
| Headline Medium | 20px | 600 | Sub-section titles |
| Title Large | 16px | 600 | Navigation items, labels |
| Body Large | 16px | 400 | Paragraph text |
| Body Medium | 14px | 400 | Secondary body |
| Body Small | 12px | 400 | Captions, metadata |
| Mono | 13px | 500 | Prices, numbers, code |

### 14.3 Responsive Breakpoints

| Name | Width | Layout |
|------|-------|--------|
| Mobile | < 768px | Single column, bottom nav |
| Tablet | 768–1023px | Two column or stacked, bottom nav |
| Desktop | ≥ 1024px | Sidebar + content layout |

---

## 15. ENVIRONMENT VARIABLES

### 15.1 Next.js

**`.env.development`** (auto-loaded in `npm run dev`):
```env
FLUTTER_APP_URL=http://localhost:5001
BACKEND_URL=http://localhost:8080
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_FLUTTER_DASHBOARD_URL=http://localhost:8080
NEXT_PUBLIC_SOCKET_URL=http://localhost:8080

COINGECKO_API_KEY=
BINANCE_API_KEY=
OPENAI_API_KEY=
ANTHROPIC_API_KEY=

NEXTAUTH_SECRET=coinastra-dev-secret
NEXTAUTH_URL=http://localhost:3000
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

**`.env.production`** (auto-loaded in Vercel):
```env
FLUTTER_APP_URL=https://coisastra-main.vercel.app
BACKEND_URL=https://crypto-backend-4557.onrender.com
NEXT_PUBLIC_APP_URL=https://coisastra-main.vercel.app
NEXT_PUBLIC_FLUTTER_DASHBOARD_URL=https://coisastra-main.vercel.app
NEXT_PUBLIC_SOCKET_URL=https://crypto-backend-4557.onrender.com

COINGECKO_API_KEY=
BINANCE_API_KEY=
OPENAI_API_KEY=
ANTHROPIC_API_KEY=

NEXTAUTH_SECRET=<strong-secret>
NEXTAUTH_URL=https://coisastra-main.vercel.app
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

### 15.2 Flutter

Environment is controlled entirely by `--dart-define=ENV=dev` at build time.
No `.env` file needed — all config is in `EndPoints` class:

```dart
static const String _env = String.fromEnvironment('ENV', defaultValue: 'prod');
static const String baseUrl = _env == 'dev'
    ? 'http://localhost:8080'
    : 'https://crypto-backend-4557.onrender.com';
```

### 15.3 Backend API (Render.com)

```env
NODE_ENV=production
PORT=8080
API_URL=https://crypto-backend-4557.onrender.com
FRONTEND_URL=https://coisastra-main.vercel.app

DATABASE_URL=postgresql://user:pass@host:5432/coinastra
REDIS_URL=redis://default:pass@host:6379

JWT_SECRET=
JWT_EXPIRY=15m
REFRESH_TOKEN_SECRET=
REFRESH_TOKEN_EXPIRY=7d
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_CALLBACK_URL=https://crypto-backend-4557.onrender.com/api/auth/google/callback

RESEND_API_KEY=
FROM_EMAIL=noreply@coisastra-main.vercel.app

COINGECKO_API_KEY=
BINANCE_API_KEY=
BINANCE_SECRET=
BINANCE_USE_WEBSOCKET_CACHE=true

ANTHROPIC_API_KEY=
OPENAI_API_KEY=
DEFAULT_AI_MODEL=claude-sonnet-4-6

STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_PRO_PRICE_ID=
STRIPE_ELITE_PRICE_ID=
```

---

## 16. DEVELOPMENT ROADMAP

### Phase 1 — Frontend + UI (COMPLETE ✅)
- [x] Next.js landing page — all components (renamed Coinastra)
- [x] Next.js auth pages — login, signup, OTP, forgot password
- [x] Next.js blog page
- [x] Flutter app shell — sidebar, topbar, responsive layout
- [x] All 16 Flutter dashboard screens
- [x] Design system — colors, typography, animations
- [x] Routing architecture (GoRouter 16 routes + Next.js rewrites)

### Phase 2 — Backend Integration (COMPLETE ✅)
- [x] Backend live on Render (`crypto-backend-4557.onrender.com`)
- [x] Dashboard REST endpoints wired (markets, trending, fear-greed, funding rates)
- [x] Socket.IO WebSocket (live ticker, whale alerts, funding rates)
- [x] AI market analysis endpoint (`/dashboard/trade-analysis`)
- [x] Trade Now endpoints (signal, OI, L/S, liquidations)
- [x] On-chain indicators endpoint (`/onchain/indicators`) — per-coin, level-colored
- [x] Exchange flows endpoints (netflow + breakdown) — per-coin, updates on coin change
- [x] Token unlocks endpoints
- [x] Market Memory endpoints (RAG patterns, similar events, market cycles)
- [x] Predictions leaderboard endpoints
- [x] Binance WebSocket cache (replaces direct browser Binance calls)

### Phase 3 — Deployment (COMPLETE ✅)
- [x] Flutter build with `--base-href /app/` + `$FLUTTER_BASE_HREF` in index.html
- [x] Single Vercel URL (`coisastra-main.vercel.app`) serving both Next.js + Flutter
- [x] Removed `output: "standalone"` (Vercel compatibility fix)
- [x] Dev/prod environment switching (one variable: `--dart-define=ENV=dev`)
- [x] Next.js `.env.development` / `.env.production` (automatic NODE_ENV switching)
- [x] WebSocket connecting to production backend (not hardcoded localhost)
- [x] Funding rate "View All" with 100-coin local search

### Phase 4 — User Data & Personalization (PLANNED)
- [ ] Auth endpoints (register, login, OTP, Google OAuth, refresh)
- [ ] User profile API
- [ ] Portfolio CRUD (holdings, performance)
- [ ] Trade journal CRUD (log trades, analytics, psychology)
- [ ] Alerts system (creation + background checker + WebSocket fire)
- [ ] AI Chat (streaming SSE + history persistence)

### Phase 5 — AI & RAG (PLANNED)
- [ ] Market Memory ingestion pipeline (nightly job, pgvector)
- [ ] Sentiment scoring pipeline (Claude Haiku batch)
- [ ] New listings AI scoring

### Phase 6 — Billing & Launch (PLANNED)
- [ ] Stripe billing (checkout, portal, webhook)
- [ ] Feature gating enforcement
- [ ] Rate limiting middleware
- [ ] Error monitoring (Sentry)
- [ ] Beta user onboarding
- [ ] Production launch

---

## 17. PROJECT METRICS

| Metric | Count |
|--------|-------|
| **Next.js Pages** | 8 |
| **Next.js Landing Components** | 12 |
| **Next.js Auth Components** | 4 |
| **Flutter Screens** | 16 |
| **Flutter Dashboard Widgets** | 7 |
| **Flutter Core Widgets** | 5 |
| **Flutter Riverpod Providers** | 21 |
| **Implemented Backend Endpoints** | 35+ |
| **Planned Backend Endpoints** | 20+ |
| **Third-Party Service Integrations** | 8 (active) |
| **PostgreSQL Tables** | 9 |
| **Vector Table** | 1 (market_patterns) |
| **Redis Key Namespaces** | 14 |
| **WebSocket Event Types** | 4 (live) |
| **Background Jobs** | 9 |
| **Auth Methods** | 2 (email/password + Google OAuth) |
| **Subscription Tiers** | 3 (Free, Pro, Institutional) |
| **Pricing Plans** | 6 (3 tiers × monthly/annual) |
| **Chart Timeframes** | 7 |
| **Technical Indicators** | 5 |
| **On-Chain Indicator Types** | 8+ |
| **Alert Types** | 6 |
| **Responsive Breakpoints** | 3 |
| **Brand Colors** | 9 |
| **Production URL** | coisastra-main.vercel.app |
| **Backend URL** | crypto-backend-4557.onrender.com |
| **Total Dart Files** | 80+ |

---

*Coinastra v1.1.0 — 2026-05-25 — Frontend + Backend integration complete, live on Vercel*



deploy both--

1)flutter build web --release --base-href /app/
2)cp -r build/web/. ../nextjs-app/public/app/            

cd ..
git add .
git commit -m "send otp"
git push origin dev_krishna