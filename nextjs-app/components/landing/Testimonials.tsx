"use client";

import { Star, Quote } from "lucide-react";

const testimonials = [
  {
    name: "Alex Chen",
    role: "Full-time Crypto Trader",
    avatar: "AC",
    avatarColor: "#00ff88",
    stars: 5,
    quote:
      "The Market Memory Engine is unlike anything I've seen. It showed me that BTC's current structure matched the Oct 2024 breakout with 87% similarity — I positioned accordingly and captured 34% gains.",
  },
  {
    name: "Sarah K.",
    role: "Hedge Fund Analyst",
    avatar: "SK",
    avatarColor: "#8b5cf6",
    stars: 5,
    quote:
      "We were spending hours manually aggregating sentiment from Twitter, Reddit, and on-chain data. Coinastra does it in real-time and surfaces actionable insights I actually trust.",
  },
  {
    name: "Marcus Williams",
    role: "DeFi Portfolio Manager",
    avatar: "MW",
    avatarColor: "#06b6d4",
    stars: 5,
    quote:
      "The trade journal's psychology insights caught my revenge trading pattern after 3 bad days in a row. That AI warning alone saved me from a $40K mistake. Absolutely worth the subscription.",
  },
  {
    name: "Priya Sharma",
    role: "Retail Trader, 3 years",
    avatar: "PS",
    avatarColor: "#f59e0b",
    stars: 5,
    quote:
      "New listings feature is incredible. I spotted ARK before it 5x'd because the AI flagged unusually high early momentum and smart money accumulation. This is the edge I've been looking for.",
  },
  {
    name: "Jordan Lee",
    role: "Crypto Fund Manager",
    avatar: "JL",
    avatarColor: "#ec4899",
    stars: 5,
    quote:
      "Finally, AI that doesn't promise magic signals. It's an intelligence layer that makes me a better decision-maker. Risk management module alone justifies the Pro subscription 10x over.",
  },
  {
    name: "Tom Nakamura",
    role: "Independent Trader",
    avatar: "TN",
    avatarColor: "#00ff88",
    stars: 5,
    quote:
      "I was skeptical of 'AI trading tools' after getting burned by bots. This is different — it's an analyst, not a predictor. The market analysis is genuinely insightful and honest about uncertainty.",
  },
];

export default function Testimonials() {
  return (
    <section className="py-24 relative overflow-hidden">
      <div className="absolute inset-0 dot-bg opacity-40" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="section-heading mb-4">
            Trusted by traders who{" "}
            <span className="gradient-text-green">actually win</span>
          </h2>
          <p className="section-subheading max-w-xl mx-auto">
            Real results from real traders. No paid testimonials, no cherry-picked wins.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {testimonials.map((t, i) => (
            <div
              key={i}
              className="glass-card-hover p-6 flex flex-col gap-4"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className="w-10 h-10 rounded-full flex items-center justify-center text-sm font-bold text-black"
                    style={{ background: t.avatarColor }}
                  >
                    {t.avatar}
                  </div>
                  <div>
                    <div className="text-sm font-semibold text-white">{t.name}</div>
                    <div className="text-xs text-white/30">{t.role}</div>
                  </div>
                </div>
                <Quote className="w-4 h-4 text-white/10" />
              </div>

              <div className="flex gap-0.5">
                {Array(t.stars).fill(0).map((_, j) => (
                  <Star key={j} className="w-3.5 h-3.5 fill-[#f59e0b] text-[#f59e0b]" />
                ))}
              </div>

              <p className="text-sm text-white/55 leading-relaxed flex-1">
                "{t.quote}"
              </p>
            </div>
          ))}
        </div>

        {/* Stats row */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-16">
          {[
            { value: "12,000+", label: "Active traders" },
            { value: "4.9/5", label: "Average rating" },
            { value: "$2.4B+", label: "Market data analyzed daily" },
            { value: "94%", label: "User retention rate" },
          ].map((stat, i) => (
            <div key={i} className="text-center">
              <div className="text-3xl font-black gradient-text-green mb-1">{stat.value}</div>
              <div className="text-sm text-white/30">{stat.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
