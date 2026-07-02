"use client";

import { useState, useEffect } from "react";
import { Shield, AlertTriangle, TrendingDown, Zap } from "lucide-react";

function fmtPrice(p: number): string {
  if (!p) return "—";
  if (p >= 10000) return `$${p.toLocaleString("en-US", { maximumFractionDigits: 0 })}`;
  return `$${p.toFixed(2)}`;
}

export default function RiskDemo() {
  const [capital, setCapital] = useState(10000);
  const [leverage, setLeverage] = useState(5);
  const [riskPercent, setRiskPercent] = useState(2);
  const [btcPrice, setBtcPrice] = useState<number | null>(null);
  const [btcChange, setBtcChange] = useState<number | null>(null);

  useEffect(() => {
    fetch("/api/market/coins")
      .then((r) => (r.ok ? r.json() : []))
      .then((coins: any[]) => {
        const btc = Array.isArray(coins) && coins.find((c: any) =>
          c.symbol === "btc" || c.id === "bitcoin"
        );
        if (btc?.current_price) setBtcPrice(btc.current_price);
        if (btc?.price_change_percentage_24h != null) setBtcChange(btc.price_change_percentage_24h);
      })
      .catch(() => {});
  }, []);

  const positionSize = (capital * riskPercent) / 100;
  const liquidationDistance = 100 / leverage;
  const maxLoss = positionSize;

  const riskLevel = leverage <= 3 ? "low" : leverage <= 7 ? "medium" : "high";
  const riskColor = riskLevel === "low" ? "#00ff88" : riskLevel === "medium" ? "#f59e0b" : "#ff3366";
  const riskLabel = riskLevel === "low" ? "Conservative" : riskLevel === "medium" ? "Moderate" : "High Risk";

  return (
    <section className="py-24 relative overflow-hidden">
      <div className="absolute inset-0"
        style={{ background: "radial-gradient(ellipse 60% 40% at 20% 50%, rgba(245,158,11,0.05) 0%, transparent 60%)" }} />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          {/* Calculator */}
          <div className="glass-card p-6 order-2 lg:order-1">
            <div className="flex items-center gap-2 mb-4">
              <Shield className="w-4 h-4 text-[#f59e0b]" />
              <span className="text-sm font-semibold text-white">Position Size Calculator</span>
              <div className="ml-auto badge-green text-[10px]">Interactive Demo</div>
            </div>
            {btcPrice && (
              <div className="flex items-center justify-between px-3 py-2 rounded-lg mb-4"
                style={{ background: "rgba(0,255,136,0.04)", border: "1px solid rgba(0,255,136,0.1)" }}>
                <div className="flex items-center gap-2">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#00ff88] animate-pulse" />
                  <span className="text-xs text-white/40 font-mono">BTC Live Price</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-mono font-bold text-white">{fmtPrice(btcPrice)}</span>
                  {btcChange != null && (
                    <span className="text-[10px] font-mono font-semibold"
                      style={{ color: btcChange >= 0 ? "#00ff88" : "#ff3366" }}>
                      {btcChange >= 0 ? "+" : ""}{btcChange.toFixed(2)}%
                    </span>
                  )}
                </div>
              </div>
            )}

            <div className="space-y-5">
              {/* Capital */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="text-xs text-white/40 uppercase tracking-wider">Account Capital</label>
                  <span className="text-sm font-mono font-bold text-white">${capital.toLocaleString()}</span>
                </div>
                <input
                  type="range" min="1000" max="100000" step="1000"
                  value={capital}
                  onChange={(e) => setCapital(Number(e.target.value))}
                  className="w-full h-1.5 rounded-full appearance-none cursor-pointer"
                  style={{ accentColor: "#00ff88" }}
                />
              </div>

              {/* Leverage */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="text-xs text-white/40 uppercase tracking-wider">Leverage</label>
                  <span className="text-sm font-mono font-bold" style={{ color: riskColor }}>{leverage}x</span>
                </div>
                <input
                  type="range" min="1" max="20" step="1"
                  value={leverage}
                  onChange={(e) => setLeverage(Number(e.target.value))}
                  className="w-full h-1.5 rounded-full appearance-none cursor-pointer"
                  style={{ accentColor: riskColor }}
                />
                <div className="flex justify-between text-[10px] text-white/20 mt-1">
                  <span>1x Safe</span>
                  <span>10x Risky</span>
                  <span>20x Danger</span>
                </div>
              </div>

              {/* Risk % */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="text-xs text-white/40 uppercase tracking-wider">Risk Per Trade</label>
                  <span className="text-sm font-mono font-bold text-white">{riskPercent}%</span>
                </div>
                <input
                  type="range" min="0.5" max="10" step="0.5"
                  value={riskPercent}
                  onChange={(e) => setRiskPercent(Number(e.target.value))}
                  className="w-full h-1.5 rounded-full appearance-none cursor-pointer"
                  style={{ accentColor: "#00ff88" }}
                />
              </div>

              {/* Results */}
              <div className="grid grid-cols-2 gap-3 pt-2">
                <div className="p-3 rounded-xl bg-white/3 border border-white/5">
                  <div className="text-[10px] text-white/30 uppercase tracking-wider mb-1">Position Size</div>
                  <div className="text-lg font-mono font-bold text-white">${positionSize.toFixed(0)}</div>
                </div>
                <div className="p-3 rounded-xl bg-white/3 border border-white/5">
                  <div className="text-[10px] text-white/30 uppercase tracking-wider mb-1">Liq. Distance</div>
                  <div className="text-lg font-mono font-bold" style={{ color: riskColor }}>
                    -{liquidationDistance.toFixed(1)}%
                  </div>
                </div>
              </div>

              {/* AI Warning */}
              {leverage > 7 && (
                <div className="flex items-start gap-3 p-3 rounded-xl border"
                  style={{ background: "rgba(255,51,102,0.05)", borderColor: "rgba(255,51,102,0.15)" }}>
                  <AlertTriangle className="w-4 h-4 text-[#ff3366] flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-xs font-semibold text-[#ff3366] mb-0.5">AI Risk Warning</p>
                    <p className="text-xs text-white/40 leading-relaxed">
                      {leverage}x leverage is very high during current volatility. A {liquidationDistance.toFixed(1)}% adverse move liquidates your position. Consider reducing to 3–5x.
                    </p>
                  </div>
                </div>
              )}

              {/* Risk Badge */}
              <div className="flex items-center justify-between p-3 rounded-xl"
                style={{ background: `${riskColor}10`, border: `1px solid ${riskColor}20` }}>
                <span className="text-xs text-white/50">Risk Level</span>
                <span className="text-sm font-semibold" style={{ color: riskColor }}>{riskLabel}</span>
              </div>
            </div>
          </div>

          {/* Content */}
          <div className="order-1 lg:order-2">
            <div className="badge-green inline-flex mb-6">
              <Shield className="w-3 h-3" />
              <span>Risk Management</span>
            </div>
            <h2 className="text-4xl md:text-5xl font-bold tracking-tight mb-6">
              <span className="gradient-text">Trade with size.</span>
              <br />
              <span className="gradient-text-green">Survive to trade again.</span>
            </h2>
            <p className="text-lg text-white/50 leading-relaxed mb-8">
              The AI risk system watches your leverage, volatility, and position sizing in real time.
              It warns you before you make a trade that could blow your account.
            </p>
            <ul className="space-y-4">
              {[
                { icon: Shield, text: "Automatic position size based on your risk tolerance" },
                { icon: AlertTriangle, text: "Liquidation price alerts before you enter" },
                { icon: TrendingDown, text: "Volatility-adjusted risk scoring" },
                { icon: Zap, text: "AI warnings when leverage exceeds safe thresholds" },
              ].map(({ icon: Icon, text }, i) => (
                <li key={i} className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                    style={{ background: "rgba(245,158,11,0.1)", border: "1px solid rgba(245,158,11,0.2)" }}>
                    <Icon className="w-4 h-4 text-[#f59e0b]" />
                  </div>
                  <span className="text-sm text-white/60">{text}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}
