"use client";
import { useEffect, useState } from "react";
import { TrendingUp, TrendingDown, RefreshCw, Activity } from "lucide-react";
import type { TickerData } from "@/hooks/useMarketSocket";

const FLUTTER_BASE =
  process.env.NEXT_PUBLIC_FLUTTER_DASHBOARD_URL ?? "http://localhost:8080";
const DASHBOARD_URL = process.env.NEXT_PUBLIC_FLUTTER_DASHBOARD_URL
  ? "/app/"
  : `${FLUTTER_BASE}/dashboard`;

interface CoinData {
  id: string;
  symbol: string;
  name: string;
  image?: string;
  current_price: number;
  price_change_percentage_24h: number;
  market_cap: number;
  total_volume: number;
  sparkline_in_7d?: { price: number[] };
  sparkline?: number[];
}

function Sparkline({ data, positive }: { data: number[]; positive: boolean }) {
  if (!data || data.length < 2) return <div className="w-20 h-8" />;
  const w = 80; const h = 32;
  const min = Math.min(...data); const max = Math.max(...data);
  const range = max - min || 1;
  const pts = data.map((v, i) => [
    (i / (data.length - 1)) * w,
    h - ((v - min) / range) * (h - 4) - 2,
  ]);
  const d = pts.map(([x, y], i) => `${i === 0 ? "M" : "L"} ${x} ${y}`).join(" ");
  const color = positive ? "#00ff88" : "#ff3366";
  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
      <path d={`${d} L ${w} ${h} L 0 ${h} Z`} fill={color} fillOpacity={0.08} />
      <path d={d} stroke={color} strokeWidth={1.5} fill="none" strokeLinecap="round" />
    </svg>
  );
}

function fmtPrice(p: number): string {
  if (!p) return "—";
  if (p >= 10000) return `$${p.toLocaleString("en-US", { maximumFractionDigits: 0 })}`;
  if (p >= 100) return `$${p.toFixed(2)}`;
  if (p >= 1) return `$${p.toFixed(3)}`;
  return `$${p.toFixed(5)}`;
}

function fmtNum(v: number): string {
  if (!v) return "—";
  if (v >= 1e9) return `$${(v / 1e9).toFixed(1)}B`;
  if (v >= 1e6) return `$${(v / 1e6).toFixed(0)}M`;
  return `$${v.toFixed(0)}`;
}

export default function LiveMarket({ tickers }: { tickers: Record<string, TickerData> }) {
  const [coins, setCoins] = useState<CoinData[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);

  const load = () => {
    setLoading(true);
    fetch("/api/market/coins")
      .then((r) => (r.ok ? r.json() : []))
      .then((data) => {
        if (Array.isArray(data) && data.length > 0) {
          setCoins(data.slice(0, 20));
          setLastUpdate(new Date());
        }
        setLoading(false);
      })
      .catch(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  // Merge live socket prices into REST coin data
  const display = coins.map((coin) => {
    const wsKey = `${coin.symbol.toUpperCase()}USDT`;
    const live = tickers[wsKey];
    const spark = coin.sparkline_in_7d?.price ?? coin.sparkline ?? [];
    return {
      ...coin,
      current_price: live?.price || coin.current_price,
      price_change_percentage_24h: live?.changePct ?? coin.price_change_percentage_24h,
      sparkline: spark,
    };
  });

  return (
    <section className="py-16 relative">
      <div className="absolute inset-0 grid-bg opacity-15" />
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <div className="flex items-center gap-2 mb-1.5">
              <div className="w-2 h-2 rounded-full bg-[#00ff88] animate-pulse" />
              <span className="text-xs text-white/40 font-mono uppercase tracking-wider">
                {Object.keys(tickers).length > 0 ? "Live via Socket" : "REST data"}
              </span>
            </div>
            <h2 className="text-2xl font-bold text-white">Live Market Prices</h2>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={load}
              disabled={loading}
              className="p-2 rounded-lg text-white/40 hover:text-white hover:bg-white/5 transition-all"
              title="Refresh"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            </button>
            <a href={DASHBOARD_URL} className="btn-secondary text-sm">
              <Activity className="w-3.5 h-3.5" />
              Full Dashboard
            </a>
          </div>
        </div>

        {/* Coin grid */}
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
          {loading && coins.length === 0
            ? Array(10).fill(0).map((_, i) => (
                <div key={i} className="glass-card p-4 animate-pulse h-28">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="w-7 h-7 rounded-full bg-white/5" />
                    <div className="flex-1 space-y-1.5">
                      <div className="h-2.5 bg-white/5 rounded w-10" />
                      <div className="h-2 bg-white/5 rounded w-14" />
                    </div>
                  </div>
                  <div className="h-4 bg-white/5 rounded w-20 mb-2" />
                  <div className="h-8 bg-white/5 rounded" />
                </div>
              ))
            : display.map((coin) => {
                const up = coin.price_change_percentage_24h >= 0;
                return (
                  <a
                    key={coin.id}
                    href={`${FLUTTER_BASE}/trade-now?coin=${coin.symbol.toUpperCase()}`}
                    className="glass-card p-4 hover:border-white/15 hover:scale-[1.02] transition-all duration-200 cursor-pointer block group"
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        {coin.image ? (
                          <img src={coin.image} alt={coin.symbol} className="w-6 h-6 rounded-full" loading="lazy" />
                        ) : (
                          <div className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center text-[8px] font-bold text-white/60">
                            {coin.symbol[0]}
                          </div>
                        )}
                        <span className="text-xs font-bold text-white group-hover:text-[#00ff88] transition-colors">
                          {coin.symbol.toUpperCase()}
                        </span>
                      </div>
                      <span className={`text-[10px] font-mono font-bold ${up ? "text-[#00ff88]" : "text-[#ff3366]"}`}>
                        {up ? "+" : ""}{(coin.price_change_percentage_24h ?? 0).toFixed(2)}%
                      </span>
                    </div>
                    <div className="text-sm font-bold font-mono text-white mb-1">
                      {fmtPrice(coin.current_price)}
                    </div>
                    <div className="flex items-end justify-between">
                      <span className="text-[9px] text-white/20">{fmtNum(coin.total_volume)}</span>
                      {coin.sparkline.length > 1 && <Sparkline data={coin.sparkline} positive={up} />}
                    </div>
                  </a>
                );
              })}
        </div>

        {lastUpdate && (
          <p className="text-center text-[10px] text-white/15 mt-4 font-mono">
            Last updated {lastUpdate.toLocaleTimeString()} · Prices update live via socket
          </p>
        )}
      </div>
    </section>
  );
}
