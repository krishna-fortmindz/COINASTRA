---
slug: rag-market-memory-technical
title: How We Built the Market Memory Engine Using RAG
excerpt: A technical deep-dive into our vector search system that matches current market states to historical patterns.
category: Engineering
readTime: 15 min read
date: Feb 28, 2026
dateISO: 2026-02-28
featured: false
author: Coinastra Team
authorTitle: AI Research Desk
---

When we set out to build Coinastra's Market Memory Engine, we had a deceptively simple goal: given the current state of the market, find the historical moments that most closely resembled it.

The challenge is that "market state" is not a single number. It's a high-dimensional vector of hundreds of indicators — price momentum, volume patterns, on-chain flows, derivatives positioning, sentiment scores, macro correlations. How do you find "similarity" across hundreds of dimensions, across thousands of historical snapshots, in real-time?

The answer: Retrieval-Augmented Generation (RAG) with custom market state embeddings.

## What Is RAG?

RAG is an AI architecture pattern that combines a retrieval system (a database you can search semantically) with a generative model (like an LLM). Instead of asking an LLM to answer from training data alone, RAG first retrieves relevant information from an external knowledge base and feeds it to the model as context.

In our case:
- The "knowledge base" is our historical market state database
- The "query" is the current market state
- The "retrieval" finds the most similar historical states
- The "generation" synthesizes insights about what happened after those historical states

## Representing Market State as Vectors

The core technical challenge: how do you turn a snapshot of market conditions into a vector (a list of numbers) that captures meaningful similarity?

We tried several approaches:

**Approach 1: Raw indicator normalization**
Simply normalize each indicator (price change %, volume ratio, funding rate, etc.) and concatenate into a vector. Fast but lossy — doesn't capture relationships between indicators.

**Approach 2: PCA dimensionality reduction**
Apply Principal Component Analysis to reduce 200+ indicators to 50 principal components. Better at capturing variance but loses interpretability.

**Approach 3: Learned embeddings (what we use)**
Train a small transformer model on historical market data to produce embeddings where "similar" market states cluster together in vector space. This approach captures complex non-linear relationships between indicators that neither raw normalization nor PCA can detect.

The training objective: market states that led to similar outcomes should have similar embeddings. This means we're encoding not just current conditions but implied future behavior into the vector representation.

## The Vector Database

We store approximately 2.3 million historical market state snapshots spanning from 2017 to present, captured at 4-hour intervals.

For the vector store, we evaluated several options:
- **Pinecone:** Excellent managed service, but cost scales significantly with query volume
- **Weaviate:** Good open-source option with rich filtering capabilities
- **pgvector:** PostgreSQL extension, easiest to integrate with existing infra
- **Qdrant:** Best performance/cost ratio for our use case

We landed on **Qdrant** with a custom sharding strategy that partitions by market regime (bull/bear/sideways) to reduce search space and improve retrieval latency.

Query latency: p50 < 40ms, p99 < 120ms for a full similarity search across 2.3M vectors.

## The Embedding Model

Our market state embedding model is a compact transformer (12 layers, 256 hidden dimensions) trained on 8 years of multi-asset crypto market data.

Input features per snapshot:
- Price and volume data for BTC, ETH, and top 20 altcoins (50 features)
- On-chain metrics: exchange flows, SOPR, MVRV, NVT ratio (30 features)
- Derivatives: funding rates, open interest, options skew (25 features)
- Sentiment: aggregated social scores, fear/greed index (15 features)
- Macro: DXY correlation, equity market correlation (10 features)
- Technical: key moving average relationships, RSI regime, Bollinger Band position (20 features)

Total: ~150 input features → 256-dimensional embedding vector.

Training used a contrastive loss function: states that preceded similar 7-day outcomes should be close in embedding space; states that preceded different outcomes should be far apart.

We trained for 48 hours on 4x A100 GPUs using our historical dataset. The resulting model achieves 73% accuracy in predicting whether a similar historical state led to a >5% gain, >5% loss, or flat outcome within 7 days — compared to a 33% baseline.

## The Retrieval Pipeline

When a user queries the Market Memory Engine:

1. **Current state extraction:** Pull live data across all ~150 features, normalize
2. **Embedding:** Run the current state through the embedding model → 256-dim vector
3. **ANN search:** Query Qdrant for top-K most similar historical vectors (we use K=50)
4. **Filtering:** Apply regime filters (e.g., "only show bull market matches" if current regime is bull)
5. **Ranking:** Re-rank by a composite score: vector similarity × recency weight × regime match weight
6. **Context assembly:** Fetch full historical context for top 10 matches (what happened after, macro context, key events)
7. **LLM synthesis:** Feed matches to Claude with a structured prompt asking for pattern analysis and actionable insights

End-to-end latency: ~800ms for a full query including LLM synthesis.

## The Similarity Score

The similarity score shown in the UI (e.g., "87% match to October 2020") is not a simple distance metric. It's a calibrated probability score combining:

- **Cosine similarity** of embedding vectors (normalized to 0-100)
- **Regime match bonus:** +10 points if historical and current market regimes match
- **Macro context penalty:** -15 points if macro conditions (DXY trend, equity correlation) differ significantly
- **Recency bias correction:** Slight upward adjustment for more recent matches (market structure evolves)

The calibration was done by backtesting: we find that when our system shows 85%+ similarity, the subsequent 7-day price direction matched the historical pattern 71% of the time. At 70-85% similarity, the match rate drops to 58%. Below 70%, we don't surface the result.

## Lessons Learned

**Lesson 1: Feature quality > feature quantity**
We initially included 350+ features. Pruning to ~150 high-quality, non-redundant features improved retrieval precision significantly. Garbage in, garbage out — noisy features corrupt the embedding space.

**Lesson 2: Market regime separation matters**
Early versions searched across all historical data equally. Adding regime-aware search (bull/bear/sideways) dramatically improved result relevance. A 90% match in a bear market is not useful if you're currently in a bull market.

**Lesson 3: LLM synthesis is the UX layer, not the core**
The value is in the retrieval. The LLM turns retrieved data into human-readable insights, but without high-quality retrieval, the LLM just hallucinates. We spent 80% of engineering effort on the retrieval system and 20% on the synthesis layer.

**Lesson 4: Latency is a product decision**
Users will tolerate 1-2 seconds for a "market memory" query because it feels like deep analysis. They won't tolerate 5+ seconds. Qdrant's performance and our ANN indexing strategy were non-negotiable for product viability.

## What's Next

We're currently working on:
- **Multi-asset correlation patterns:** Extend the engine to find patterns across asset pairs, not just single assets
- **Intraday snapshots:** Currently 4-hour intervals; moving to 1-hour for more granular matching
- **User-specific history:** Allow the engine to match against a user's own trade history, not just market history

The Market Memory Engine is one of the most technically interesting systems we've built. If you have questions about the architecture or want to discuss implementation details, we'd love to hear from you.

---

*The Market Memory Engine is live in the Coinastra app. Try a free pattern match against today's market conditions.*
