"use client";
import { useEffect, useState } from "react";
import { ArrowRight, Zap, Activity, ExternalLink } from "lucide-react";
import type { TickerData } from "@/hooks/useMarketSocket";

const FLUTTER_BASE =
  process.env.NEXT_PUBLIC_FLUTTER_DASHBOARD_URL ?? "http://localhost:8080";
const DASHBOARD_URL = process.env.NEXT_PUBLIC_FLUTTER_DASHBOARD_URL
  ? "/app/"
  : `${FLUTTER_BASE}/dashboard`;

const COINS = [
  { symbol: "BTC", ws: "BTCUSDT", coinId: "bitcoin",           color: "#f7931a", abbr: "₿"  },
  { symbol: "ETH", ws: "ETHUSDT", coinId: "ethereum",          color: "#627eea", abbr: "Ξ"  },
  { symbol: "SOL", ws: "SOLUSDT", coinId: "solana",            color: "#9945ff", abbr: "◎"  },
  { symbol: "BNB", ws: "BNBUSDT", coinId: "binancecoin",       color: "#f0b90b", abbr: "B"  },
  { symbol: "XRP", ws: "XRPUSDT", coinId: "ripple",            color: "#00aae4", abbr: "X"  },
  { symbol: "DOGE",ws: "DOGEUSDT",coinId: "dogecoin",          color: "#c3a634", abbr: "Ð"  },
  { symbol: "ARB", ws: "ARBUSDT", coinId: "arbitrum",          color: "#12aaff", abbr: "A"  },
  { symbol: "AVAX",ws: "AVAXUSDT",coinId: "avalanche-2",       color: "#e84142", abbr: "A"  },
  { symbol: "LINK",ws: "LINKUSDT",coinId: "chainlink",         color: "#2a5ada", abbr: "⬡"  },
  { symbol: "INJ", ws: "INJUSDT", coinId: "injective-protocol",color: "#00b4d8", abbr: "I"  },
];

const CHART_POINTS = [42,45,43,48,52,49,55,58,54,60,64,61,58,62,68,72,69,74,78,75,80,77,82,85,88,84,79,83,87,91];

function MiniChart({ positive = true }: { positive?: boolean }) {
  const w = 100; const h = 36;
  const pts = CHART_POINTS;
  const min = Math.min(...pts); const max = Math.max(...pts);
  const norm = (v: number) => h - ((v - min) / (max - min)) * h;
  const d = pts.map((v, i) => `${i === 0 ? "M" : "L"} ${(i / (pts.length - 1)) * w} ${norm(v)}`).join(" ");
  const c = positive ? "#00ff88" : "#ff3366";
  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
      <defs>
        <linearGradient id={`hg${positive}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={c} stopOpacity="0.25" />
          <stop offset="100%" stopColor={c} stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={`${d} L ${w} ${h} L 0 ${h} Z`} fill={`url(#hg${positive})`} />
      <path d={d} fill="none" stroke={c} strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function fmt(p: number): string {
  if (!p) return "—";
  if (p >= 10000) return `$${p.toLocaleString("en-US", { maximumFractionDigits: 0 })}`;
  if (p >= 100)   return `$${p.toFixed(2)}`;
  if (p >= 1)     return `$${p.toFixed(3)}`;
  return `$${p.toFixed(4)}`;
}

const FALLBACK_SUMMARY =
  "BTC showing bullish momentum. RSI 67 — not overbought. Key resistance $98.4K. Funding rates neutral. Scale on pullbacks to $95K support.";

export default function Hero({
  socketTickers = {},
  connected = false,
}: {
  socketTickers?: Record<string, TickerData>;
  connected?: boolean;
}) {
  const [fearGreed, setFearGreed] = useState<{ value: number; classification: string } | null>(null);
  const [aiText, setAiText] = useState("");
  const [aiSummary, setAiSummary] = useState(FALLBACK_SUMMARY);

  // Fetch AI market summary (fear/greed + Claude-generated text)
  useEffect(() => {
    fetch("/api/ai/market-summary")
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => {
        if (d?.summary) setAiSummary(d.summary);
        if (d?.fearGreed != null)
          setFearGreed({ value: d.fearGreed, classification: d.classification ?? "Neutral" });
      })
      .catch(() => {});
  }, []);

  // Typewriter effect — reruns when aiSummary changes
  useEffect(() => {
    setAiText("");
    let i = 0;
    const t = setInterval(() => {
      if (i <= aiSummary.length) setAiText(aiSummary.slice(0, i++));
      else clearInterval(t);
    }, 22);
    return () => clearInterval(t);
  }, [aiSummary]);


  const fgValue = fearGreed?.value ?? 72;
  const fgLabel = fearGreed?.classification ?? "Greed";
  const fgColor = fgValue >= 60 ? "#00ff88" : fgValue >= 45 ? "#f59e0b" : "#ff3366";
  const fgDash = `${(fgValue / 100) * 100.53} ${100.53 - (fgValue / 100) * 100.53}`;

  const btcLive = socketTickers["BTCUSDT"];
  const btcUp = (btcLive?.changePct ?? 2.4) >= 0;

  // Build ticker items from socket data, fallback to static
  const tickerItems = COINS.map((c) => {
    const live = socketTickers[c.ws];
    return {
      ...c,
      price: live ? fmt(live.price) : "—",
      change: live ? `${live.changePct >= 0 ? "+" : ""}${(live.changePct ?? 0).toFixed(2)}%` : "",
      up: live ? live.changePct >= 0 : true,
    };
  });

  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden pt-16">
      <div className="absolute inset-0 grid-bg opacity-60" />
      <div className="absolute inset-0 bg-gradient-hero" />
      <div
        className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[600px] h-[600px] rounded-full"
        style={{ background: "radial-gradient(circle, rgba(0,255,136,0.06) 0%, transparent 70%)" }}
      />

      {/* Live Ticker tape */}
      <div
        className="absolute top-16 left-0 right-0 overflow-hidden py-3 border-b border-white/5"
        style={{ background: "rgba(10,11,15,0.85)" }}
      >
        <div className="flex">
          <div className="ticker-tape">
            {[...tickerItems, ...tickerItems].map((item, i) => (
              <a
                key={i}
                href={`${FLUTTER_BASE}/trade-now?coin=${item.symbol}`}
                className="flex items-center gap-2 whitespace-nowrap hover:opacity-70 transition-opacity"
              >
                <span className="text-xs font-mono font-semibold text-white/60">{item.symbol}</span>
                <span className="text-xs font-mono font-bold text-white">{item.price}</span>
                {item.change && (
                  <span className={`text-xs font-mono font-semibold ${item.up ? "text-[#00ff88]" : "text-[#ff3366]"}`}>
                    {item.change}
                  </span>
                )}
                <span className="text-white/10 mx-2">|</span>
              </a>
            ))}
          </div>
        </div>
      </div>

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-8">
        {/* Badge */}
        <div className="flex justify-center mb-8">
          <div className="badge-green animate-pulse-slow">
            <Activity className="w-3 h-3" />
            <span>{connected ? "Live Socket Connected" : "AI Market Analysis"}</span>
          </div>
        </div>

        {/* Headline */}
        <div className="text-center max-w-4xl mx-auto mb-8">
          <h1 className="text-5xl sm:text-6xl lg:text-7xl font-black tracking-tight leading-[1.05] mb-6">
            <span className="gradient-text">Your AI Trading</span>
            <br />
            <span className="gradient-text-green">Copilot</span>{" "}
            <span className="gradient-text">for Smarter</span>
            <br />
            <span className="gradient-text">Crypto Decisions</span>
          </h1>
          <p className="text-lg sm:text-xl text-white/50 max-w-2xl mx-auto leading-relaxed">
            Real-time AI analysis, live market data, whale alerts and risk management —
            everything a serious trader needs, in one platform.
          </p>
        </div>

        {/* Primary CTA */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16">
          <a href={DASHBOARD_URL} className="btn-primary group text-base px-10 py-4">
            Open Dashboard
            <ExternalLink className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
          </a>
          <a href="#features" className="btn-secondary text-base px-8 py-4 group">
            Explore Features
            <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
          </a>
        </div>

        {/* Cards */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 max-w-5xl mx-auto">
          {/* AI Analysis */}
          <div className="lg:col-span-2 glass-card p-5 relative overflow-hidden hover:border-white/10 transition-all duration-300">
            <div
              className="absolute top-0 right-0 w-32 h-32 rounded-full -mr-16 -mt-16"
              style={{ background: "radial-gradient(circle, rgba(0,255,136,0.06) 0%, transparent 70%)" }}
            />
            <div className="flex items-center gap-2 mb-4">
              <div className="w-2 h-2 rounded-full bg-[#00ff88] animate-pulse" />
              <span className="text-xs text-white/40 font-mono uppercase tracking-wider">AI Market Summary · Live</span>
            </div>
            <div className="flex items-start gap-3">
              <div
                className="w-8 h-8 rounded-lg flex-shrink-0 flex items-center justify-center"
                style={{ background: "linear-gradient(135deg, #00ff88, #00cc6a)" }}
              >
                <Zap className="w-4 h-4 text-black" />
              </div>
              <p className="text-sm text-white/80 leading-relaxed font-mono min-h-[60px]">
                {aiText}
                <span className="inline-block w-0.5 h-3.5 bg-[#00ff88] ml-0.5 animate-pulse" />
              </p>
            </div>
            <div className="mt-4 flex items-center gap-4 pt-4 border-t border-white/5">
              <div className="flex items-center gap-1.5">
                <span className="text-xs text-white/30">F&G</span>
                <span className="text-xs font-mono font-bold" style={{ color: fgColor }}>
                  {fgValue} · {fgLabel}
                </span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="text-xs text-white/30">Socket</span>
                <span className={`text-xs font-mono font-semibold ${connected ? "text-[#00ff88]" : "text-white/30"}`}>
                  {connected ? "●  Live" : "○  Connecting"}
                </span>
              </div>
            </div>
          </div>

          {/* Right column */}
          <div className="flex flex-col gap-4">
            {/* BTC Live */}
            <a
              href={`${FLUTTER_BASE}/trade-now?coin=BTC`}
              className="glass-card p-4 hover:border-white/10 transition-all duration-300 block cursor-pointer"
            >
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div
                    className="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold"
                    style={{ background: "linear-gradient(135deg, #f7931a, #e8820a)" }}
                  >
                    ₿
                  </div>
                  <div>
                    <div className="text-xs font-semibold text-white">BTC</div>
                    <div className="text-[10px] text-white/30">Bitcoin</div>
                  </div>
                </div>
                {btcLive && (
                  <span
                    className="text-[10px] font-mono font-bold px-2 py-0.5 rounded"
                    style={{
                      background: btcUp ? "rgba(0,255,136,0.1)" : "rgba(255,51,102,0.1)",
                      color: btcUp ? "#00ff88" : "#ff3366",
                    }}
                  >
                    {btcLive.changePct >= 0 ? "+" : ""}{btcLive.changePct.toFixed(2)}%
                  </span>
                )}
              </div>
              <div className="flex items-end justify-between">
                <span className="text-lg font-bold font-mono text-white">
                  {btcLive ? fmt(btcLive.price) : "—"}
                </span>
                <MiniChart positive={btcUp} />
              </div>
            </a>

            {/* Fear & Greed */}
            <div className="glass-card p-4 hover:border-white/10 transition-all duration-300">
              <div className="text-[10px] text-white/30 uppercase tracking-wider mb-2">Fear & Greed Index</div>
              <div className="flex items-center gap-3">
                <div className="relative w-12 h-12 flex-shrink-0">
                  <svg viewBox="0 0 36 36" className="w-12 h-12 -rotate-90">
                    <circle cx="18" cy="18" r="15.9" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="3" />
                    <circle
                      cx="18" cy="18" r="15.9" fill="none"
                      stroke={fgColor} strokeWidth="3"
                      strokeDasharray={fgDash}
                      strokeLinecap="round"
                      style={{ transition: "stroke-dasharray 0.8s ease" }}
                    />
                  </svg>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <span className="text-xs font-black" style={{ color: fgColor }}>{fgValue}</span>
                  </div>
                </div>
                <div>
                  <div className="text-sm font-semibold text-white">{fgLabel}</div>
                  <div className="text-[10px] text-white/40">Crowd sentiment</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="flex flex-wrap items-center justify-center gap-6 mt-12 text-sm text-white/25">
          <span className="font-semibold text-white/50">Live data</span>
          <span className="w-1 h-1 rounded-full bg-white/15" />
          <span>10 coins tracked via socket</span>
          <span className="w-1 h-1 rounded-full bg-white/15" />
          <span>Binance + CoinGecko</span>
          <span className="w-1 h-1 rounded-full bg-white/15" />
          <span>Groq AI analysis</span>
        </div>
      </div>
    </section>
  );
}
