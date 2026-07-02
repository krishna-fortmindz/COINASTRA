"use client";

import { useState } from "react";
import { Plus, Minus } from "lucide-react";

const faqs = [
  {
    q: "Is Coinastra a trading bot that places trades automatically?",
    a: "No. Coinastra is an intelligence and analysis platform, not an automated trading bot. It helps you make better decisions — it does not place trades on your behalf. You remain in full control.",
  },
  {
    q: "How accurate is the Market Memory Engine?",
    a: "The engine uses semantic similarity matching on 10+ years of historical data. Similarity scores reflect structural pattern matching, not price predictions. Coinastra is transparent about confidence levels and always provides historical outcomes so you can judge for yourself.",
  },
  {
    q: "What data sources does Coinastra use for sentiment analysis?",
    a: "Coinastra aggregates Twitter/X (via official API), Reddit (top crypto subreddits), on-chain data (whale wallets, exchange flows), ETF inflow/outflow data, and curated news sources. All processed through AI for signal extraction.",
  },
  {
    q: "Can I connect my exchange account?",
    a: "Yes. On the Pro and Institutional plans, you can connect Binance, Bybit, OKX, and Coinbase via read-only API keys. Coinastra never requests withdrawal permissions — your funds are always safe.",
  },
  {
    q: "Is the new coin listings feature real-time?",
    a: "Yes. Coinastra monitors Binance and Bybit listing announcements 24/7 via WebSocket feeds. You'll receive alerts within seconds of a new listing going live, along with AI-generated analysis of potential momentum.",
  },
  {
    q: "How does the AI Trade Journal work?",
    a: "You log your trades (entry, exit, size, emotion at time of trade). The AI analyzes patterns in your trading behavior — detecting things like revenge trading after losses, overtrading in volatile conditions, and suboptimal entry timing. It gives you weekly psychology reports.",
  },
  {
    q: "What is Coinastra's refund policy?",
    a: "All paid plans include a 14-day money-back guarantee. If you're not satisfied for any reason, contact support within 14 days of your first payment for a full refund. No questions asked.",
  },
  {
    q: "Does Coinastra offer an API for institutional clients?",
    a: "Yes. The Institutional plan includes REST API access to Coinastra's AI analysis endpoints, sentiment scores, and market memory data. Contact the sales team for custom integrations and enterprise SLAs.",
  },
];

export default function FAQ() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section id="faq" className="py-24 relative">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="section-heading mb-4">
            Frequently asked{" "}
            <span className="gradient-text-green">questions</span>
          </h2>
          <p className="section-subheading">
            Everything you need to know about Coinastra.
          </p>
        </div>

        <div className="space-y-2">
          {faqs.map((faq, i) => (
            <div
              key={i}
              className={`glass-card overflow-hidden transition-all duration-200 ${
                open === i ? "border-white/10" : "hover:border-white/8"
              }`}
            >
              <button
                className="w-full flex items-center justify-between p-5 text-left gap-4"
                onClick={() => setOpen(open === i ? null : i)}
              >
                <span className={`text-sm font-medium transition-colors ${
                  open === i ? "text-white" : "text-white/70"
                }`}>
                  {faq.q}
                </span>
                <div className={`w-6 h-6 rounded-full flex-shrink-0 flex items-center justify-center transition-all ${
                  open === i ? "bg-[#00ff88]/15 text-[#00ff88]" : "bg-white/5 text-white/30"
                }`}>
                  {open === i ? <Minus className="w-3 h-3" /> : <Plus className="w-3 h-3" />}
                </div>
              </button>
              {open === i && (
                <div className="px-5 pb-5">
                  <div className="h-px bg-white/5 mb-4" />
                  <p className="text-sm text-white/50 leading-relaxed">{faq.a}</p>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
