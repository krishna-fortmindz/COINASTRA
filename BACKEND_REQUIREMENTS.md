# CoinPilot — Complete Backend Requirements

> Analysis of all features across the Next.js landing layer and Flutter dashboard.
> The frontend is fully built; this document defines every backend piece needed to make it live.

---

## TABLE OF CONTENTS

1. [Architecture Overview](#architecture-overview)
2. [Custom API Endpoints](#custom-api-endpoints)
3. [Third-Party API Integrations](#third-party-api-integrations)
4. [AI + RAG Endpoints](#ai--rag-endpoints)
5. [Databases](#databases)
6. [Authentication & Sessions](#authentication--sessions)
7. [Real-Time Infrastructure](#real-time-infrastructure)
8. [Background Jobs & Workers](#background-jobs--workers)
9. [Environment Variables (Full List)](#environment-variables-full-list)
10. [Tech Stack Recommendation](#tech-stack-recommendation)

---

## Architecture Overview

```
Client (Next.js + Flutter Web)
        │
        ▼
   API Gateway / Nginx
        │
   ┌────┴────────────────┐
   │                     │
   ▼                     ▼
Backend API          WebSocket Server
(REST / GraphQL)     (real-time prices,
                      alerts, chat stream)
   │
   ├── PostgreSQL       (users, trades, alerts, journal)
   ├── Redis            (sessions, cache, rate limiting, pub/sub)
   ├── Pinecone / pgvector  (vector store — RAG / Market Memory)
   └── TimescaleDB (optional)  (OHLCV time-series — if self-hosting)
```

Recommended runtime: **Node.js (Fastify) or Python (FastAPI)** — both have mature LLM + vector tooling.

---

## Custom API Endpoints

### 1. Auth

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/auth/register` | Email + password signup |
| POST | `/api/auth/login` | Email + password login → returns JWT + refresh token |
| POST | `/api/auth/logout` | Invalidate refresh token |
| POST | `/api/auth/refresh` | Exchange refresh token for new access token |
| POST | `/api/auth/forgot-password` | Send OTP to email |
| POST | `/api/auth/verify-otp` | Verify OTP code |
| POST | `/api/auth/reset-password` | Set new password after OTP |
| GET  | `/api/auth/google` | Redirect to Google OAuth consent |
| GET  | `/api/auth/google/callback` | Handle Google OAuth callback |
| GET  | `/api/auth/me` | Return current user profile (JWT required) |

---

### 2. User & Profile

| Method | Route | Description |
|--------|-------|-------------|
| GET  | `/api/user/profile` | Get full profile (avatar, name, plan, etc.) |
| PATCH | `/api/user/profile` | Update name, avatar, timezone, currency preference |
| GET  | `/api/user/preferences` | Get notification & display preferences |
| PATCH | `/api/user/preferences` | Update preferences |
| DELETE | `/api/user/account` | Delete account + all data (GDPR) |

---

### 3. Market Data (Proxy + Cache Layer)

> CoinGecko + Binance calls should be proxied through the backend to hide API keys, add caching, and unify the response format.

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/market/coins` | Paginated list of coins (price, 24h change, mcap, volume) |
| GET | `/api/market/coins/:coinId` | Single coin detail (all metadata) |
| GET | `/api/market/coins/:coinId/ohlcv` | OHLCV candles — query: `interval`, `from`, `to` |
| GET | `/api/market/coins/:coinId/orderbook` | Current orderbook depth |
| GET | `/api/market/fear-greed` | Fear & Greed Index (Alternative.me) |
| GET | `/api/market/global` | Global market cap, dominance, total volume |
| GET | `/api/market/trending` | Trending coins (last 24h) |
| GET | `/api/market/funding-rates` | Perpetual funding rates (Binance) |
| GET | `/api/market/new-listings` | Newly listed coins with AI momentum score |
| GET | `/api/market/whale-alerts` | Large on-chain transactions (Whale Alert / Glassnode) |

---

### 4. Portfolio

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/portfolio` | User's portfolio summary (holdings, P&L, allocation) |
| POST | `/api/portfolio/holdings` | Add holding (coin, amount, avg buy price) |
| PATCH | `/api/portfolio/holdings/:id` | Update holding |
| DELETE | `/api/portfolio/holdings/:id` | Remove holding |
| GET | `/api/portfolio/performance` | Historical portfolio value over time |

---

### 5. Trade Journal

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/journal` | Paginated list of all trade journal entries |
| POST | `/api/journal` | Log a new trade (entry/exit price, size, pair, notes, mood/psychology) |
| GET | `/api/journal/:id` | Single journal entry detail |
| PATCH | `/api/journal/:id` | Update journal entry |
| DELETE | `/api/journal/:id` | Delete journal entry |
| GET | `/api/journal/stats` | Win rate, avg R:R, profit factor, psychology patterns |

---

### 6. Risk Management

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/risk/position-size` | Calculate position size (account size, risk %, entry, stop-loss) |
| POST | `/api/risk/rr-calculator` | Risk:Reward ratio calculator |
| GET | `/api/risk/max-drawdown` | Historical max drawdown for a coin |

---

### 7. Alerts

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/alerts` | All user alerts |
| POST | `/api/alerts` | Create price alert (coin, condition: above/below, target price) |
| PATCH | `/api/alerts/:id` | Update alert |
| DELETE | `/api/alerts/:id` | Delete alert |
| GET | `/api/alerts/history` | Fired alert history |

---

### 8. News & Sentiment

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/sentiment/news` | Latest crypto news with AI sentiment score |
| GET | `/api/sentiment/social` | Twitter/X + Reddit aggregate sentiment per coin |
| GET | `/api/sentiment/coins/:coinId` | All sentiment signals for a specific coin |
| GET | `/api/sentiment/on-chain` | On-chain indicators (NVT, SOPR, exchange netflow) |

---


### 9. Dashboard Widgets

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/dashboard/summary` | Single endpoint: prices, Fear/Greed, trending, whale alerts, AI summary (cached 60s) |

---

## Third-Party API Integrations

### Price & Market Data

| Provider | Purpose | API Key Env Var | Notes |
|----------|---------|-----------------|-------|
| **CoinGecko Pro** | Coin list, prices, OHLCV, metadata, trending | `COINGECKO_API_KEY` | 500 calls/min on Pro |
| **Binance** | Real-time prices, orderbook, funding rates, klines | `BINANCE_API_KEY` + `BINANCE_SECRET` | WebSocket for real-time |
| **Alternative.me** | Fear & Greed Index | None (free) | Cache 1h |
| **CoinMarketCal** | Upcoming events, new listings calendar | `COINMARKETCAL_API_KEY` | |
| **Whale Alert** | Large on-chain transfers | `WHALE_ALERT_API_KEY` | |
| **Glassnode** | On-chain analytics (NVT, SOPR, exchange flows) | `GLASSNODE_API_KEY` | |

### Social & Sentiment

| Provider | Purpose | API Key Env Var | Notes |
|----------|---------|-----------------|-------|
| **LunarCrush** | Social sentiment, volume, engagement per coin | `LUNARCRUSH_API_KEY` | Best crypto social API |
| **CryptoPanic** | Curated crypto news with bullish/bearish votes | `CRYPTOPANIC_API_KEY` | |
| **Twitter/X API v2** | Tweet volume + sentiment per coin | `TWITTER_BEARER_TOKEN` | Use Academic track for history |
| **Reddit API** | Subreddit post sentiment (r/bitcoin etc.) | `REDDIT_CLIENT_ID` + `REDDIT_SECRET` | |

### Auth

| Provider | Purpose | Env Vars |
|----------|---------|----------|
| **Google OAuth 2.0** | Social login | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` |
| **Resend / SendGrid** | Transactional emails (OTP, welcome, alerts) | `RESEND_API_KEY` or `SENDGRID_API_KEY` |
| **Twilio** (optional) | SMS OTP fallback | `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` |

### Payments (for subscription tiers)

| Provider | Purpose | Env Vars |
|----------|---------|----------|
| **Stripe** | Subscription billing (Free / Pro / Elite plans visible in UI) | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` |

---

## AI + RAG Endpoints

### 1. AI Chat (Conversational Intelligence)

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/ai/chat` | Send message, get streaming response (SSE) |
| GET | `/api/ai/chat/history` | Paginated conversation history |
| DELETE | `/api/ai/chat/history` | Clear chat history |

**Implementation:**
- Model: `claude-sonnet-4-6` (primary) or `gpt-4o`
- System prompt injected with: current prices, Fear/Greed, user portfolio context
- Streaming via Server-Sent Events (SSE)
- Store each turn in PostgreSQL `chat_messages` table
- Env: `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`

---

### 2. AI Market Analysis

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/ai/analysis/:coinId` | On-demand AI analysis for a coin |
| GET | `/api/ai/analysis/market` | Overall market regime analysis |

**Implementation:**
- Fetch coin data → feed to LLM with structured prompt
- Cache result for 15 minutes (Redis)
- Returns: trend direction, key levels, risk factors, AI confidence score

---

### 3. Market Memory — RAG Pattern Matching

> This is the core RAG feature shown on the landing page.

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/ai/market-memory/search` | Submit current market pattern → find similar historical periods |
| GET | `/api/ai/market-memory/patterns` | List saved/notable patterns |
| GET | `/api/ai/market-memory/patterns/:id` | Single pattern detail with outcome |

**RAG Pipeline:**

```
1. Ingest Phase (background job, runs nightly)
   ├── Fetch historical OHLCV for BTC/ETH/top coins (CoinGecko)
   ├── Chunk into 30/60/90-day windows
   ├── Compute features per window:
   │     price change %, volume profile, RSI, MACD, BB width,
   │     funding rate regime, Fear/Greed avg, BTC dominance
   ├── Generate embedding vector (OpenAI text-embedding-3-large or custom model)
   └── Upsert into vector store (Pinecone or pgvector)

2. Query Phase (on user request)
   ├── Compute same features for current market window
   ├── Embed current window
   ├── Vector similarity search → top 5 historical matches
   ├── For each match: retrieve what happened next (30/60/90 days after)
   └── Feed matches + outcomes into LLM → generate narrative explanation
```

**Vector Store:** Pinecone (managed) or pgvector (self-hosted in Postgres)
**Embedding Model:** `text-embedding-3-large` (OpenAI) or `embed-english-v3.0` (Cohere)
**Metadata stored per vector:** `coinId`, `windowStart`, `windowEnd`, `features (JSON)`, `outcomeData (JSON)`

---

### 4. Sentiment AI Scoring

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/ai/sentiment/score` | Score raw news/tweet text → bullish/bearish/neutral + confidence |

**Implementation:**
- Run LLM classification on news batches
- Cache per article/tweet (Redis, 24h TTL)
- Also use LunarCrush pre-computed scores to reduce LLM costs

---

### 5. New Listings AI Score

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/ai/listings/score/:coinId` | AI momentum + legitimacy score for a new listing |

**Input signals to LLM:** social volume, whitepaper summary, team info, tokenomics, whale accumulation data
**Output:** score 0–100, risk flags, summary

---

## Databases

### A. PostgreSQL — Primary Relational Database

**Tables:**

```sql
-- Users
users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,               -- null if Google OAuth only
  google_id TEXT UNIQUE,
  name TEXT,
  avatar_url TEXT,
  plan TEXT DEFAULT 'free',         -- free | pro | elite
  email_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)

-- Sessions / Refresh Tokens
refresh_tokens (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ
)

-- OTP Codes
otp_codes (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  purpose TEXT NOT NULL,            -- forgot_password | email_verify
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT false
)

-- Portfolio Holdings
portfolio_holdings (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  coin_id TEXT NOT NULL,            -- e.g. "bitcoin"
  coin_symbol TEXT NOT NULL,
  amount NUMERIC(20, 8) NOT NULL,
  avg_buy_price_usd NUMERIC(20, 8),
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)

-- Trade Journal
trade_journal (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  pair TEXT NOT NULL,               -- e.g. BTC/USDT
  direction TEXT NOT NULL,          -- long | short
  entry_price NUMERIC(20, 8),
  exit_price NUMERIC(20, 8),
  size NUMERIC(20, 8),
  pnl_usd NUMERIC(20, 8),
  pnl_percent NUMERIC(10, 4),
  entry_at TIMESTAMPTZ,
  exit_at TIMESTAMPTZ,
  notes TEXT,
  psychology TEXT,                  -- fomo | patient | revenge | disciplined
  strategy TEXT,
  outcome TEXT,                     -- win | loss | breakeven
  created_at TIMESTAMPTZ
)

-- Price Alerts
alerts (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  coin_id TEXT NOT NULL,
  coin_symbol TEXT NOT NULL,
  condition TEXT NOT NULL,          -- above | below | percent_change
  target_value NUMERIC(20, 8) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  fired_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
)

-- AI Chat Messages
chat_messages (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,               -- user | assistant
  content TEXT NOT NULL,
  model TEXT,                       -- which LLM was used
  tokens_used INTEGER,
  created_at TIMESTAMPTZ
)

-- User Preferences
user_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  currency TEXT DEFAULT 'USD',
  timezone TEXT DEFAULT 'UTC',
  theme TEXT DEFAULT 'dark',
  email_alerts BOOLEAN DEFAULT true,
  push_alerts BOOLEAN DEFAULT true,
  default_coins TEXT[],             -- coin_ids to show on dashboard
  updated_at TIMESTAMPTZ
)

-- Subscriptions (Stripe)
subscriptions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  plan TEXT NOT NULL,               -- pro | elite
  status TEXT NOT NULL,             -- active | canceled | past_due
  current_period_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
```

---

### B. Redis — Cache, Sessions, Rate Limiting, Pub/Sub

**Key namespaces:**

| Key Pattern | TTL | Purpose |
|-------------|-----|---------|
| `session:{userId}` | 7 days | Session data |
| `market:coins:list` | 60s | Cached coin list response |
| `market:coin:{coinId}` | 30s | Single coin data |
| `market:ohlcv:{coinId}:{interval}` | 5m | OHLCV candle data |
| `market:feargreed` | 1h | Fear & Greed index |
| `market:global` | 60s | Global market stats |
| `market:trending` | 5m | Trending coins |
| `market:funding` | 60s | Funding rates |
| `ai:analysis:{coinId}` | 15m | LLM market analysis per coin |
| `sentiment:news` | 10m | Latest news with scores |
| `sentiment:social:{coinId}` | 15m | Social sentiment per coin |
| `ratelimit:{userId}:{endpoint}` | sliding window | Rate limiting per user |
| `ratelimit:ip:{ip}` | sliding window | IP-based rate limit |

**Pub/Sub channels:**
- `prices:{coinId}` — real-time price tick for WebSocket broadcast
- `alert:fired:{userId}` — trigger notification delivery
- `whale:alert` — new whale transaction detected

---

### C. Vector Database — RAG / Market Memory

**Option A: pgvector (recommended for self-hosted simplicity)**
```sql
-- Enable extension
CREATE EXTENSION vector;

-- Market pattern embeddings
market_patterns (
  id UUID PRIMARY KEY,
  coin_id TEXT NOT NULL,
  window_start DATE NOT NULL,
  window_end DATE NOT NULL,
  interval_days INTEGER NOT NULL,   -- 30 | 60 | 90
  embedding vector(1536) NOT NULL,  -- OpenAI ada-002 dims
  features JSONB NOT NULL,          -- price_change, volume_profile, rsi, etc.
  outcome_data JSONB,               -- what happened next (price, % change, etc.)
  created_at TIMESTAMPTZ
)

CREATE INDEX ON market_patterns USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);
```

**Option B: Pinecone (managed, scales without tuning)**
- Index name: `coinpilot-market-memory`
- Dimensions: 1536 (OpenAI) or 3072 (text-embedding-3-large)
- Metric: cosine
- Metadata fields: `coinId`, `windowStart`, `windowEnd`, `intervalDays`, `outcomeData`

---

### D. TimescaleDB (Optional — only if self-hosting price history)

> If relying entirely on CoinGecko for historical OHLCV, skip this. Add only if you need sub-minute data or want independence from CoinGecko rate limits.

```sql
-- OHLCV candles
ohlcv (
  time TIMESTAMPTZ NOT NULL,
  coin_id TEXT NOT NULL,
  open NUMERIC(20, 8),
  high NUMERIC(20, 8),
  low NUMERIC(20, 8),
  close NUMERIC(20, 8),
  volume NUMERIC(30, 8)
)

SELECT create_hypertable('ohlcv', 'time');
CREATE INDEX ON ohlcv (coin_id, time DESC);
```

---

## Authentication & Sessions

- **JWT** (short-lived, 15 min) + **Refresh Token** (7 days, stored in DB + httpOnly cookie)
- **Google OAuth 2.0** via Passport.js / NextAuth adapter
- **OTP** (6-digit, 10 min expiry) via email using Resend/SendGrid
- **Password hashing:** bcrypt (cost factor 12)
- **Rate limiting:** 5 failed logins per IP per 15 min → temporary block

---

## Real-Time Infrastructure

### WebSocket Server

All real-time features require a persistent WebSocket connection from the Flutter client.

**Channels / events:**

| Event | Direction | Description |
|-------|-----------|-------------|
| `subscribe:price` | Client → Server | Subscribe to price ticks for coin(s) |
| `price:tick` | Server → Client | Real-time price update |
| `alert:fired` | Server → Client | Price alert triggered |
| `whale:alert` | Server → Client | Large on-chain transaction |
| `ai:chat:token` | Server → Client | Streaming AI chat token (for SSE or WS) |
| `sentiment:update` | Server → Client | New sentiment signal for subscribed coins |

**Implementation options:**
- **Socket.io** (Node.js) — easiest with Redis pub/sub adapter
- **Phoenix Channels** (Elixir) — most scalable for high fan-out
- Binance already provides WebSocket streams — backend subscribes and fans out to clients

---

## Background Jobs & Workers

Use **BullMQ** (Node.js) or **Celery** (Python) with Redis as broker.

| Job | Schedule | Description |
|-----|----------|-------------|
| `ingest-market-history` | Daily 00:00 UTC | Fetch OHLCV history for top 100 coins, compute features, embed, upsert to vector store |
| `score-new-listings` | Every 4h | Fetch CoinMarketCal + CoinGecko new listings, run AI scoring |
| `aggregate-sentiment` | Every 15m | Pull LunarCrush + CryptoPanic + Twitter data, score with LLM, cache in Redis |
| `check-price-alerts` | Every 30s | Fetch current prices, compare to active alerts, fire WebSocket events |
| `send-alert-emails` | On trigger | Send email notification when alert fires |
| `update-fear-greed` | Every 1h | Refresh Fear & Greed from Alternative.me |
| `clean-expired-tokens` | Daily | Delete expired OTPs and refresh tokens |

---

## Environment Variables (Full List)

```env
# ─── Server ───────────────────────────────────────────────
NODE_ENV=production
PORT=4000
API_URL=https://api.aitradingcopilot.com

# ─── Frontend URLs ────────────────────────────────────────
NEXT_PUBLIC_APP_URL=https://aitradingcopilot.com
NEXT_PUBLIC_API_URL=https://api.aitradingcopilot.com
NEXT_PUBLIC_WS_URL=wss://api.aitradingcopilot.com
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX

# ─── Database ─────────────────────────────────────────────
DATABASE_URL=postgresql://user:pass@localhost:5432/coinpilot
REDIS_URL=redis://localhost:6379

# ─── Auth ─────────────────────────────────────────────────
JWT_SECRET=your-jwt-secret-min-32-chars
JWT_EXPIRY=15m
REFRESH_TOKEN_EXPIRY=7d
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_CALLBACK_URL=https://api.aitradingcopilot.com/api/auth/google/callback

# ─── Email ────────────────────────────────────────────────
RESEND_API_KEY=
FROM_EMAIL=noreply@aitradingcopilot.com

# ─── Market Data ──────────────────────────────────────────
COINGECKO_API_KEY=
BINANCE_API_KEY=
BINANCE_SECRET=
WHALE_ALERT_API_KEY=
GLASSNODE_API_KEY=
COINMARKETCAL_API_KEY=

# ─── Sentiment ────────────────────────────────────────────
LUNARCRUSH_API_KEY=
CRYPTOPANIC_API_KEY=
TWITTER_BEARER_TOKEN=
REDDIT_CLIENT_ID=
REDDIT_SECRET=

# ─── AI / LLM ─────────────────────────────────────────────
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
DEFAULT_AI_MODEL=claude-sonnet-4-6     # or gpt-4o

# ─── Vector DB ────────────────────────────────────────────
# Option A: pgvector (uses DATABASE_URL above, no extra var)
# Option B: Pinecone
PINECONE_API_KEY=
PINECONE_INDEX=coinpilot-market-memory
PINECONE_ENVIRONMENT=us-east-1-aws

# ─── Payments ─────────────────────────────────────────────
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_PRO_PRICE_ID=
STRIPE_ELITE_PRICE_ID=

# ─── Push Notifications (optional) ────────────────────────
FCM_SERVER_KEY=                        # Firebase Cloud Messaging for mobile alerts
```

---

## Tech Stack Recommendation

| Layer | Recommended | Alternative |
|-------|-------------|-------------|
| **Backend Runtime** | Node.js + Fastify | Python + FastAPI |
| **Database** | PostgreSQL 16 + pgvector | Supabase (managed Postgres + pgvector) |
| **Cache** | Redis 7 (Upstash managed) | Valkey |
| **Job Queue** | BullMQ (Redis-backed) | pg-boss (Postgres-backed) |
| **WebSocket** | Socket.io + Redis adapter | Ably (managed) |
| **Auth** | Custom JWT + Passport.js | Clerk / Supabase Auth |
| **Email** | Resend | SendGrid |
| **Vector Store** | pgvector (co-located) | Pinecone (managed) |
| **Embeddings** | OpenAI text-embedding-3-large | Cohere embed-english-v3 |
| **LLM** | Claude Sonnet (Anthropic) + GPT-4o fallback | |
| **Payments** | Stripe | |
| **Deployment** | Railway / Render / Fly.io | AWS ECS / GCP Cloud Run |
| **Monitoring** | Sentry (errors) + Grafana (metrics) | Datadog |

---

## Summary Count

| Category | Count |
|----------|-------|
| Custom API endpoints | 46 |
| Third-party integrations | 13 services |
| AI/RAG endpoints | 7 |
| PostgreSQL tables | 9 |
| Redis key namespaces | 11 |
| Background jobs | 7 |
| WebSocket event types | 6 |



Here's the full backend endpoint map per section:

  ---
  Trade Now
  
  ┌──────────────────────────────────────────────┬─────────────────────────────────┬────────┬──────────────────────────┐
  │                     Data                     │            Endpoint             │ Method │          Params          │
  ├──────────────────────────────────────────────┼─────────────────────────────────┼────────┼──────────────────────────┤
  │ AI signal (verdict, confidence, entry/TP/SL) │ /api/v1/analysis/signal         │ GET    │ symbol=BTCUSDT           │
  ├──────────────────────────────────────────────┼─────────────────────────────────┼────────┼──────────────────────────┤
  │ Funding rate                                 │ /api/v1/dashboard/funding-rates │ GET    │ symbols=BTCUSDT — exists │
  ├──────────────────────────────────────────────┼─────────────────────────────────┼────────┼──────────────────────────┤
  │ Open Interest + change                       │ /api/v1/analysis/open-interest  │ GET    │ symbol=BTCUSDT           │
  ├──────────────────────────────────────────────┼─────────────────────────────────┼────────┼──────────────────────────┤
  │ Long/Short ratio                             │ /api/v1/analysis/long-short     │ GET    │ symbol=BTCUSDT           │
  ├──────────────────────────────────────────────┼─────────────────────────────────┼────────┼──────────────────────────┤
  │ Liquidation walls                            │ /api/v1/analysis/liquidations   │ GET    │ symbol=BTCUSDT           │
  ├──────────────────────────────────────────────┼─────────────────────────────────┼────────┼──────────────────────────┤
  │ News & social sentiment                      │ /api/v1/analysis/sentiment      │ GET    │ symbol=BTCUSDT           │
  ├──────────────────────────────────────────────┼─────────────────────────────────┼────────┼──────────────────────────┤
  │ Historical setups                            │ /api/v1/analysis/history        │ GET    │ symbol=BTCUSDT&limit=5   │
  └──────────────────────────────────────────────┴─────────────────────────────────┴────────┴──────────────────────────┘
  
  ▎ All /api/v1/analysis/* routes are new — need to be created on backend.
  
  ---
  Charts

  ┌──────────────────────┬─────────────────────────────┬────────┬───────────────────────────────────────────────┐
  │         Data         │          Endpoint           │ Method │                    Params                     │
  ├──────────────────────┼─────────────────────────────┼────────┼───────────────────────────────────────────────┤
  │ Candlestick OHLCV    │ /api/v1/dashboard/klines    │ GET    │ symbol=BTCUSDT&interval=1h&limit=100 — exists │
  ├──────────────────────┼─────────────────────────────┼────────┼───────────────────────────────────────────────┤
  │ RSI values           │ /api/v1/analysis/indicators │ GET    │ symbol=BTCUSDT&type=rsi&interval=1h           │
  ├──────────────────────┼─────────────────────────────┼────────┼───────────────────────────────────────────────┤
  │ MACD values          │ /api/v1/analysis/indicators │ GET    │ symbol=BTCUSDT&type=macd&interval=1h          │
  ├──────────────────────┼─────────────────────────────┼────────┼───────────────────────────────────────────────┤
  │ EMA / Bollinger      │ /api/v1/analysis/indicators │ GET    │ symbol=BTCUSDT&type=ema&interval=1h           │
  ├──────────────────────┼─────────────────────────────┼────────┼───────────────────────────────────────────────┤
  │ AI pattern detection │ /api/v1/analysis/patterns   │ GET    │ symbol=BTCUSDT&interval=1h                    │
  ├──────────────────────┼─────────────────────────────┼────────┼───────────────────────────────────────────────┤
  │ Live candle updates  │ Socket.IO market:kline      │ —      │ subscribe via dashboard:subscribe             │
  └──────────────────────┴─────────────────────────────┴────────┴───────────────────────────────────────────────┘
  
  ▎ /api/v1/dashboard/klines already exists. /api/v1/analysis/indicators and market:kline socket are new.
  
  ---
  Order Book

  ┌────────────────────────┬───────────────────────────────┬────────┬───────────────────────────────────┐
  │          Data          │           Endpoint            │ Method │              Params               │
  ├────────────────────────┼───────────────────────────────┼────────┼───────────────────────────────────┤
  │ Bids & asks depth      │ /api/v1/dashboard/order-book  │ GET    │ symbol=BTCUSDT&limit=20 — exists  │
  ├────────────────────────┼───────────────────────────────┼────────┼───────────────────────────────────┤
  │ Last price / spread    │ /api/v1/dashboard/ticker-24hr │ GET    │ symbol=BTCUSDT — exists           │
  ├────────────────────────┼───────────────────────────────┼────────┼───────────────────────────────────┤
  │ Key price levels (S/R) │ /api/v1/analysis/levels       │ GET    │ symbol=BTCUSDT                    │
  ├────────────────────────┼───────────────────────────────┼────────┼───────────────────────────────────┤
  │ Live book updates      │ Socket.IO market:trade        │ —      │ subscribe via dashboard:subscribe │
  └────────────────────────┴───────────────────────────────┴────────┴───────────────────────────────────┘
  
  ▎ 2 REST endpoints already exist. market:trade socket and /api/v1/analysis/levels are new.
  
  ---
  Summary — What backend needs to build

  Already exists (just needs wiring in Flutter):
  - /api/v1/dashboard/klines → Charts
  - /api/v1/dashboard/order-book → Order Book
  - /api/v1/dashboard/ticker-24hr → Order Book
  - /api/v1/dashboard/funding-rates → Trade Now

  New routes needed:
  /api/v1/analysis/signal          → Trade Now verdict, entry/TP/SL
  /api/v1/analysis/open-interest   → Trade Now OI
  /api/v1/analysis/long-short      → Trade Now L/S ratio
  /api/v1/analysis/liquidations    → Trade Now liq. walls
  /api/v1/analysis/sentiment       → Trade Now news sentiment
  /api/v1/analysis/history         → Trade Now past setups
  /api/v1/analysis/indicators      → Charts RSI/MACD/EMA/BB
  /api/v1/analysis/patterns        → Charts AI pattern overlay
  /api/v1/analysis/levels          → Order Book S/R levels
  
  Socket.IO events needed (currently subscribed but not handled):
  market:kline   → live candle updates for Charts
  market:trade   → live trade feed for Order Book
 ---
  Flutter

  ┌─────────────────────────────────────────────┬────────────────────┐
  │                   Command                   │    Environment     │
  ├─────────────────────────────────────────────┼────────────────────┤
  │ flutter run -d chrome --dart-define=ENV=dev │ Local backend      │
  ├─────────────────────────────────────────────┼────────────────────┤
  │ flutter run -d chrome                       │ Production backend │
  ├─────────────────────────────────────────────┼────────────────────┤
  │ flutter build web --dart-define=ENV=dev     │ Build with local   │
  ├─────────────────────────────────────────────┼────────────────────┤
  │ flutter build web                           │ Build with prod    │
  └─────────────────────────────────────────────┴────────────────────┘

  ---
  Next.js

  ┌───────────────────┬────────────────────────────────────────┐
  │      Command      │              Environment               │
  ├───────────────────┼────────────────────────────────────────┤
  │ npm run dev       │ Auto uses .env.development (localhost) │
  ├───────────────────┼────────────────────────────────────────┤
  │ npm run build     │ Auto uses .env.production (live URLs)  │
  ├───────────────────┼────────────────────────────────────────┤
  │ npx vercel --prod │ Uses .env.production                   │
  └───────────────────┴────────────────────────────────────────┘