import { NextResponse } from "next/server";
import Anthropic from "@anthropic-ai/sdk";

export const dynamic = "force-dynamic";

const BACKEND_URL = process.env.BACKEND_URL ??"http://10.255.251.45:5000";

interface FearGreedData {
  value: number;
  classification: string;
}

interface SocialSentimentData {
  fearAndGreed: { score: number; sentiment: string };
  binanceFutures: {
    longShortRatio: number;
    longAccountPercent: number;
    shortAccountPercent: number;
  };
}

interface MarketData {
  symbol: string;
  current_price: number;
  price_change_percentage_24h: number;
}

export async function GET() {
  // Fetch fear/greed
  let fearGreed: FearGreedData = { value: 50, classification: "Neutral" };
  try {
    const res = await fetch(`${BACKEND_URL}/api/v1/dashboard/fear-greed`);
    if (res.ok) {
      const json = await res.json();
      const fg = json?.data ?? json;
      fearGreed = {
        value: Number(fg?.value ?? 50),
        classification: String(fg?.classification ?? "Neutral"),
      };
    }
  } catch {}

  // Fetch social sentiment
  let social: SocialSentimentData = {
    fearAndGreed: { score: 50, sentiment: "Neutral" },
    binanceFutures: {
      longShortRatio: 1,
      longAccountPercent: 50,
      shortAccountPercent: 50,
    },
  };
  try {
    const res = await fetch(
      `${BACKEND_URL}/api/sentiment/social?symbol=BTCUSDT`
    );
    if (res.ok) {
      const json = await res.json();
      const d = json?.data ?? json;
      social = {
        fearAndGreed: {
          score: Number(d?.fearAndGreed?.score ?? fearGreed.value),
          sentiment: String(d?.fearAndGreed?.sentiment ?? fearGreed.classification),
        },
        binanceFutures: {
          longShortRatio: Number(d?.binanceFutures?.longShortRatio ?? 1),
          longAccountPercent: Number(d?.binanceFutures?.longAccountPercent ?? 50),
          shortAccountPercent: Number(d?.binanceFutures?.shortAccountPercent ?? 50),
        },
      };
    }
  } catch {}

  // Fetch BTC price
  let btcPrice = 0;
  let btcChange = 0;
  try {
    const res = await fetch(
      `${BACKEND_URL}/api/v1/dashboard/markets?vsCurrency=usd&perPage=1`
    );
    if (res.ok) {
      const json = await res.json();
      const coins: MarketData[] = json?.data ?? json;
      const btc = Array.isArray(coins) ? coins[0] : null;
      if (btc) {
        btcPrice = Number(btc.current_price ?? 0);
        btcChange = Number(btc.price_change_percentage_24h ?? 0);
      }
    }
  } catch {}

  const { longAccountPercent, shortAccountPercent, longShortRatio } =
    social.binanceFutures;
  const fgScore = fearGreed.value;
  const fgClass = fearGreed.classification;

  // Build summary
  let summary = "";

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (apiKey) {
    try {
      const client = new Anthropic({ apiKey });
      const userContent =
        `BTC price: $${btcPrice.toLocaleString()} (${btcChange >= 0 ? "+" : ""}${btcChange.toFixed(2)}% 24h). ` +
        `Fear & Greed: ${fgScore} (${fgClass}). ` +
        `Long/Short ratio: ${longShortRatio.toFixed(2)} (longs ${longAccountPercent.toFixed(1)}% / shorts ${shortAccountPercent.toFixed(1)}%). ` +
        `Write a 1-2 sentence market analyst summary under 160 characters as a trader would say it.`;

      const message = await client.messages.create({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 100,
        system:
          "You are a concise crypto market analyst. Summarize the market in 1-2 short sentences like an experienced trader. Keep it under 160 characters total.",
        messages: [{ role: "user", content: userContent }],
      });

      const block = message.content[0];
      if (block.type === "text") {
        summary = block.text.trim();
      }
    } catch {}
  }

  // Fallback template summary
  if (!summary) {
    const direction = btcChange >= 0 ? "up" : "down";
    const sentiment =
      fgScore >= 70
        ? "greedy"
        : fgScore <= 30
        ? "fearful"
        : "neutral";
    summary = `BTC ${direction} ${Math.abs(btcChange).toFixed(1)}% to $${btcPrice.toLocaleString()}. Market sentiment ${sentiment} (${fgScore}), longs at ${longAccountPercent.toFixed(1)}%.`;
    if (summary.length > 160) {
      summary = summary.slice(0, 157) + "...";
    }
  }

  const btcStr = btcPrice > 0 ? `BTC $${btcPrice.toLocaleString()} (${btcChange >= 0 ? "+" : ""}${btcChange.toFixed(2)}%)` : "BTC price loading";
  const marketState = `${btcStr} · F&G ${fgScore} ${fgClass} · Longs ${longAccountPercent.toFixed(1)}% / Shorts ${shortAccountPercent.toFixed(1)}% · L/S ratio ${longShortRatio.toFixed(3)}`;

  return NextResponse.json({
    summary,
    marketState,
    fearGreed: fgScore,
    classification: fgClass,
    longPct: longAccountPercent,
    shortPct: shortAccountPercent,
    lsRatio: longShortRatio,
  });
}
