"use client";

import { useEffect, useState } from "react";
import { Activity, TrendingUp, TrendingDown } from "lucide-react";

type NewsItem = {
  title: string;
  sentiment: string;
  timeAgo: string;
  source: string;
  url?: string;
};

function fromUnix(ts: number): string {
  const diff = (Date.now() / 1000 - ts);
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

const STATIC_NEWS: NewsItem[] = [
  { title: "BlackRock Bitcoin ETF records 3rd largest inflow day", sentiment: "Bullish", timeAgo: "2h ago", source: "CoinDesk" },
  { title: "Fed signals potential rate pause in Q2 2026", sentiment: "Bullish", timeAgo: "4h ago", source: "CoinDesk" },
  { title: "Crypto exchange sees $400M in open interest added", sentiment: "Neutral", timeAgo: "5h ago", source: "CoinTelegraph" },
  { title: "BTC miner selling pressure near 5-year low", sentiment: "Bullish", timeAgo: "7h ago", source: "CoinDesk" },
];

export default function SentimentDemo() {
  const [fgScore, setFgScore] = useState(25);
  const [fgSentiment, setFgSentiment] = useState("Extreme Fear");
  const [longPct, setLongPct] = useState(54.35);
  const [shortPct, setShortPct] = useState(45.65);
  const [lsRatio, setLsRatio] = useState(1.1906);
  const [avgScore, setAvgScore] = useState(0.14);
  const [overallStatus, setOverallStatus] = useState("Neutral");
  const [news, setNews] = useState<NewsItem[]>(STATIC_NEWS);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Fetch social sentiment (fear/greed + long/short)
    fetch("/api/ai/market-summary")
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => {
        if (!d) return;
        if (d.fearGreed != null) setFgScore(Math.round(d.fearGreed));
        if (d.classification) setFgSentiment(d.classification);
        if (d.longPct != null) setLongPct(d.longPct);
        if (d.shortPct != null) setShortPct(d.shortPct);
        if (d.lsRatio != null) setLsRatio(d.lsRatio);
      })
      .catch(() => {});

    // Fetch live news
    fetch("/api/sentiment/news")
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (!data) return;
        // Backend returns array of articles directly from our route
        const articles: NewsItem[] = (Array.isArray(data) ? data : [])
          .slice(0, 4)
          .map((a: any) => {
            // sentiment can be a string or an object like { label, score }
            const rawSent = a.sentiment;
            const sentStr = typeof rawSent === "string"
              ? rawSent
              : rawSent?.label ?? rawSent?.value ?? rawSent?.classification ?? "Neutral";
            return {
              title: a.title ?? "",
              sentiment: String(sentStr),
              timeAgo: a.publishedOn ? fromUnix(Number(a.publishedOn)) : "",
              source: a.source ?? "",
              url: a.url,
            };
          })
          .filter((a: NewsItem) => a.title);
        if (articles.length > 0) setNews(articles);
        // Also update avg score if available from response body
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const fgColor = fgScore >= 60 ? "#00ff88" : fgScore >= 45 ? "#f59e0b" : "#ff3366";
  const tierLabels = ["Extreme Fear", "Fear", "Neutral", "Greed", "Extreme Greed"];
  const activeTierIdx = fgScore >= 75 ? 4 : fgScore >= 55 ? 3 : fgScore >= 45 ? 2 : fgScore >= 25 ? 1 : 0;

  return (
    <section className="py-24 relative overflow-hidden">
      <div className="absolute inset-0 grid-bg opacity-30" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <div className="badge-green inline-flex mb-4">
            <Activity className="w-3 h-3" />
            <span>Sentiment Intelligence</span>
          </div>
          <h2 className="section-heading mb-4">
            Know what the market{" "}
            <span className="gradient-text-green">is feeling</span>
          </h2>
          <p className="section-subheading max-w-xl mx-auto">
            Aggregate sentiment from social, on-chain, and institutional signals into one clear picture.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Fear & Greed Meter */}
          <div className="glass-card p-6 flex flex-col items-center text-center">
            <div className="flex items-center gap-2 mb-4">
              <div className="w-1.5 h-1.5 rounded-full bg-[#00ff88] animate-pulse" />
              <div className="text-xs text-white/30 uppercase tracking-wider font-mono">Fear &amp; Greed Index · Live</div>
            </div>
            <div className="relative w-36 h-36 mb-6">
              <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                <circle cx="50" cy="50" r="42" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="8" />
                <circle
                  cx="50" cy="50" r="42" fill="none"
                  stroke={fgColor} strokeWidth="8"
                  strokeLinecap="round"
                  strokeDasharray={`${fgScore * 2.64} ${264 - fgScore * 2.64}`}
                  style={{ transition: "stroke-dasharray 0.8s ease" }}
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-3xl font-black" style={{ color: fgColor }}>{fgScore}</span>
                <span className="text-[10px] text-white/30 uppercase tracking-wider">{fgSentiment}</span>
              </div>
            </div>
            <div className="w-full space-y-2">
              {tierLabels.map((label, i) => (
                <div key={i} className={`flex items-center justify-between text-xs px-3 py-1.5 rounded-lg transition-all ${
                  i === activeTierIdx ? "text-white" : "text-white/30"
                }`} style={i === activeTierIdx ? { background: `${fgColor}15`, color: fgColor } : {}}>
                  <span>{label}</span>
                  {i === activeTierIdx && <div className="w-1.5 h-1.5 rounded-full animate-pulse" style={{ background: fgColor }} />}
                </div>
              ))}
            </div>
          </div>

          {/* Binance Futures Long/Short */}
          <div className="glass-card p-6">
            <div className="text-xs text-white/30 uppercase tracking-wider font-mono mb-5">Market Signals · Live</div>
            <div className="space-y-5">
              {/* Fear & Greed bar */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <Activity className="w-3.5 h-3.5" style={{ color: fgColor }} />
                    <span className="text-sm font-medium text-white">Fear &amp; Greed</span>
                  </div>
                  <span className="text-sm font-mono font-bold" style={{ color: fgColor }}>{fgScore}</span>
                </div>
                <div className="h-1.5 bg-white/5 rounded-full overflow-hidden">
                  <div className="h-full rounded-full" style={{ width: `${fgScore}%`, background: fgColor, transition: "width 0.8s ease" }} />
                </div>
              </div>

              {/* Long accounts */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <TrendingUp className="w-3.5 h-3.5 text-[#00ff88]" />
                    <span className="text-sm font-medium text-white">Long Accounts</span>
                  </div>
                  <span className="text-sm font-mono font-bold text-[#00ff88]">{longPct.toFixed(1)}%</span>
                </div>
                <div className="h-1.5 bg-white/5 rounded-full overflow-hidden">
                  <div className="h-full rounded-full bg-[#00ff88]" style={{ width: `${longPct}%`, transition: "width 0.8s ease" }} />
                </div>
              </div>

              {/* Short accounts */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <TrendingDown className="w-3.5 h-3.5 text-[#ff3366]" />
                    <span className="text-sm font-medium text-white">Short Accounts</span>
                  </div>
                  <span className="text-sm font-mono font-bold text-[#ff3366]">{shortPct.toFixed(1)}%</span>
                </div>
                <div className="h-1.5 bg-white/5 rounded-full overflow-hidden">
                  <div className="h-full rounded-full bg-[#ff3366]" style={{ width: `${shortPct}%`, transition: "width 0.8s ease" }} />
                </div>
              </div>
            </div>

            {/* L/S ratio bar */}
            <div className="mt-6 pt-5 border-t border-white/5">
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs text-white/30 uppercase tracking-wider">Binance Futures L/S Ratio</span>
                <span className="text-xs font-mono font-bold" style={{ color: longPct > 50 ? "#00ff88" : "#ff3366" }}>
                  {lsRatio.toFixed(4)}
                </span>
              </div>
              <div className="flex h-3 rounded-full overflow-hidden">
                <div className="bg-[#00ff88] transition-all duration-700" style={{ width: `${longPct}%` }} />
                <div className="bg-[#ff3366] flex-1" />
              </div>
              <div className="flex justify-between mt-1.5 text-[10px] text-white/30">
                <span>Longs {longPct.toFixed(1)}%</span>
                <span>Shorts {shortPct.toFixed(1)}%</span>
              </div>
            </div>
          </div>

          {/* Live News Feed */}
          <div className="glass-card p-6">
            <div className="flex items-center justify-between mb-5">
              <div className="text-xs text-white/30 uppercase tracking-wider font-mono">AI News Digest · Live</div>
              <div className="w-2 h-2 rounded-full bg-[#00ff88] animate-pulse" />
            </div>
            <div className="space-y-3">
              {loading
                ? Array(4).fill(0).map((_, i) => (
                    <div key={i} className="p-3 rounded-xl border border-white/5 animate-pulse">
                      <div className="h-2 bg-white/5 rounded w-16 mb-2" />
                      <div className="h-2.5 bg-white/5 rounded w-full mb-1" />
                      <div className="h-2.5 bg-white/5 rounded w-3/4" />
                    </div>
                  ))
                : news.map((item, i) => {
                  const sent = String(item.sentiment ?? "neutral").toLowerCase();
                  const sentColor = sent === "bullish" ? "#00ff88" : sent === "bearish" ? "#ff3366" : "#f59e0b";
                  const El = item.url ? "a" : "div";
                  return (
                    <El
                      key={i}
                      {...(item.url ? { href: item.url, target: "_blank", rel: "noopener noreferrer" } : {})}
                      className="p-3 rounded-xl border border-white/5 hover:border-white/10 transition-all cursor-pointer group block"
                    >
                      <div className="flex items-start justify-between gap-2 mb-1.5">
                        <span className="text-[10px] font-semibold uppercase tracking-wider px-1.5 py-0.5 rounded"
                          style={{ background: `${sentColor}18`, color: sentColor }}>
                          {sent}
                        </span>
                        <span className="text-[10px] text-white/20 flex-shrink-0">{item.timeAgo}</span>
                      </div>
                      <p className="text-xs text-white/60 leading-relaxed group-hover:text-white/80 transition-colors line-clamp-2">
                        {item.title}
                      </p>
                      {item.source && (
                        <p className="text-[10px] text-white/20 mt-1">{item.source}</p>
                      )}
                    </El>
                  );
                })}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
