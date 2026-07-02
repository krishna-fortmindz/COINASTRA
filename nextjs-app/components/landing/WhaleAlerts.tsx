"use client";
import { useEffect, useRef } from "react";
import { ArrowRight } from "lucide-react";
import type { WhaleAlert, FundingRateItem } from "@/hooks/useMarketSocket";

function fmtUsd(v: number): string {
  if (v >= 1e9) return `$${(v / 1e9).toFixed(2)}B`;
  if (v >= 1e6) return `$${(v / 1e6).toFixed(0)}M`;
  if (v >= 1e3) return `$${(v / 1e3).toFixed(0)}K`;
  return `$${v.toFixed(0)}`;
}

function timeAgo(ts: number): string {
  const diff = (Date.now() - (ts > 1e12 ? ts : ts * 1000)) / 1000;
  if (diff < 60) return `${Math.floor(diff)}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  return `${Math.floor(diff / 3600)}h ago`;
}

const COIN_EMOJIS: Record<string, string> = {
  BTC: "₿", ETH: "Ξ", SOL: "◎", BNB: "B", XRP: "✕", DOGE: "Ð", USDT: "$", USDC: "$",
};

export default function WhaleAlerts({
  whales,
  fundingRates,
}: {
  whales: WhaleAlert[];
  fundingRates: FundingRateItem[];
}) {
  const hasData = whales.length > 0 || fundingRates.length > 0;
  if (!hasData) return null;

  return (
    <section className="py-16 relative overflow-hidden">
      <div className="absolute inset-0"
        style={{ background: "radial-gradient(ellipse 60% 40% at 50% 50%, rgba(0,255,136,0.03) 0%, transparent 70%)" }} />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Whale Alerts */}
          {whales.length > 0 && (
            <div>
              <div className="flex items-center gap-2 mb-6">
                <div className="w-2 h-2 rounded-full bg-[#00ff88] animate-pulse" />
                <h3 className="text-lg font-bold text-white">Live Whale Movements</h3>
              </div>
              <div className="space-y-2">
                {whales.slice(0, 6).map((w, i) => {
                  const bearish = w.toExchange;
                  const color = bearish ? "#ff3366" : "#00ff88";
                  const emoji = COIN_EMOJIS[w.symbol] ?? "🐋";
                  return (
                    <div key={i} className="glass-card p-3 flex items-center gap-3">
                      <div
                        className="w-9 h-9 rounded-xl flex items-center justify-center text-sm font-bold flex-shrink-0"
                        style={{ background: `${color}15`, border: `1px solid ${color}25` }}
                      >
                        {emoji}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-1.5 text-xs">
                          <span className="font-bold text-white">{w.symbol}</span>
                          <span className="text-white/30 truncate max-w-[60px]">{w.from}</span>
                          <ArrowRight className="w-3 h-3 text-white/20 flex-shrink-0" />
                          <span className="text-white/30 truncate max-w-[60px]">{w.to}</span>
                        </div>
                        <div className="text-[10px] text-white/20 mt-0.5">
                          {timeAgo(w.timestamp)}
                        </div>
                      </div>
                      <div className="text-right flex-shrink-0">
                        <div className="text-sm font-bold font-mono" style={{ color }}>
                          {fmtUsd(w.amountUsd)}
                        </div>
                        <div
                          className="text-[9px] font-medium px-1.5 py-0.5 rounded mt-0.5"
                          style={{ background: `${color}15`, color }}
                        >
                          {bearish ? "→ Exchange" : "← Cold"}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Live Funding Rates */}
          {fundingRates.length > 0 && (
            <div>
              <div className="flex items-center gap-2 mb-6">
                <div className="w-2 h-2 rounded-full bg-[#f59e0b] animate-pulse" />
                <h3 className="text-lg font-bold text-white">Live Funding Rates</h3>
              </div>
              <div className="glass-card p-4">
                <div className="space-y-3">
                  {fundingRates.map((f, i) => {
                    const color = f.positive ? "#00ff88" : "#ff3366";
                    const isHigh = Math.abs(f.rate) > 0.0004;
                    return (
                      <div key={i} className="flex items-center justify-between py-1.5 border-b border-white/5 last:border-0">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold text-white w-20">{f.symbol}</span>
                          {isHigh && (
                            <span className="text-[8px] px-1.5 py-0.5 rounded bg-[#f59e0b]/15 text-[#f59e0b] font-semibold">HIGH</span>
                          )}
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="text-[10px] text-white/30">
                            {f.positive ? "Longs paying" : "Shorts paying"}
                          </span>
                          <span
                            className="text-sm font-mono font-bold w-20 text-right"
                            style={{ color }}
                          >
                            {f.formatted}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
                <p className="text-[10px] text-white/15 mt-3 font-mono">
                  Live from Binance Futures · 8h intervals
                </p>
              </div>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
