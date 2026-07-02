import { NextResponse } from "next/server";
import Anthropic from "@anthropic-ai/sdk";

export const dynamic = "force-dynamic";

const BACKEND_URL = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";

interface Pattern {
  date: string;
  title: string;
  similarity: number;
  outcome: string;
  positive: boolean;
  description: string;
}

const FALLBACK_PATTERNS: Pattern[] = [
  {
    date: "Oct 2024",
    title: "BTC Breakout Phase",
    similarity: 87,
    outcome: "+34% over 45 days",
    positive: true,
    description:
      "RSI breakout from 55 zone, ETF inflows surge, funding neutral.",
  },
  {
    date: "Mar 2024",
    title: "Pre-Halving Accumulation",
    similarity: 71,
    outcome: "+28% over 30 days",
    positive: true,
    description:
      "Low funding rates, whale accumulation, exchange outflows increasing.",
  },
  {
    date: "Jan 2023",
    title: "Recovery Rally",
    similarity: 63,
    outcome: "+18% over 21 days",
    positive: true,
    description:
      "Bottom formation after capitulation, sentiment shifting from extreme fear.",
  },
];

export async function GET() {
  // Fetch fear/greed
  let fgScore = 50;
  let fgClass = "Neutral";
  try {
    const res = await fetch(`${BACKEND_URL}/api/v1/dashboard/fear-greed`);
    if (res.ok) {
      const json = await res.json();
      const fg = json?.data ?? json;
      fgScore = Number(fg?.value ?? 50);
      fgClass = String(fg?.classification ?? "Neutral");
    }
  } catch {}

  // Fetch social sentiment
  let longPct = 50;
  let fgSocialScore = fgScore;
  try {
    const res = await fetch(
      `${BACKEND_URL}/api/sentiment/social?symbol=BTCUSDT`
    );
    if (res.ok) {
      const json = await res.json();
      const d = json?.data ?? json;
      longPct = Number(d?.binanceFutures?.longAccountPercent ?? 50);
      fgSocialScore = Number(d?.fearAndGreed?.score ?? fgScore);
    }
  } catch {}

  // Fetch trending coins
  let trendingNames = "";
  try {
    const res = await fetch(
      `${BACKEND_URL}/api/v1/dashboard/trending`,
      { next: { revalidate: 1800 } }
    );
    if (res.ok) {
      const json = await res.json();
      const coins: Array<{ item: { name: string; symbol: string; market_cap_rank: number } }> =
        json?.data?.coins ?? json?.coins ?? [];
      trendingNames = coins
        .slice(0, 3)
        .map((c) => `${c.item.name} (${c.item.symbol}, rank #${c.item.market_cap_rank})`)
        .join(", ");
    }
  } catch {}

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (apiKey) {
    try {
      const client = new Anthropic({ apiKey });

      const userContent =
        `Current market data — Fear & Greed: ${fgSocialScore} (${fgClass}). ` +
        `Long accounts: ${longPct.toFixed(1)}%. ` +
        (trendingNames ? `Trending coins: ${trendingNames}. ` : "") +
        `Based on this data, identify exactly 3 historical Bitcoin market patterns that most closely match current conditions. ` +
        `Respond with a JSON array only — no markdown, no explanation. ` +
        `Each object must have: date (string like "Mon YYYY"), title (string), similarity (integer 60-95), outcome (string like "+X% over Y days"), positive (boolean), description (string under 100 chars).`;

      const message = await client.messages.create({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 600,
        system:
          "You are a Bitcoin market historian and pattern analyst. Return ONLY a valid JSON array with exactly 3 pattern objects. No markdown, no code fences, no explanation.",
        messages: [{ role: "user", content: userContent }],
      });

      const block = message.content[0];
      if (block.type === "text") {
        const text = block.text.trim();
        // Strip possible markdown code fences
        const clean = text.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim();
        const parsed: Pattern[] = JSON.parse(clean);
        if (Array.isArray(parsed) && parsed.length === 3) {
          return NextResponse.json(parsed);
        }
      }
    } catch {}
  }

  return NextResponse.json(FALLBACK_PATTERNS);
}
