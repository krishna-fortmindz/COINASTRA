"use client";

import { Check, Zap, Crown, Rocket, Lock } from "lucide-react";
import Link from "next/link";
import { useState } from "react";

const plans = [
  {
    name: "Starter",
    icon: Zap,
    price: { monthly: 0, annual: 0 },
    description: "For traders just getting started with AI-powered insights.",
    color: "#00ff88",
    features: [
      "AI market summaries (3/day)",
      "Basic sentiment dashboard",
      "Fear & Greed index",
      "2 watchlist coins",
      "Community Discord access",
    ],
    cta: "Start Free",
    href: "/auth/signup",
    popular: false,
    comingSoon: false,
  },
  {
    name: "Pro",
    icon: Rocket,
    price: { monthly: 49, annual: 39 },
    description: "The complete AI trading intelligence suite for serious traders.",
    color: "#8b5cf6",
    features: [
      "Unlimited AI market analysis",
      "Market Memory Engine (full access)",
      "Advanced sentiment + news feed",
      "New listings early detection",
      "Risk management calculator",
      "AI trade journal + psychology",
      "Whale alerts & funding rates",
      "TradingView-style charts + AI overlay",
      "AI chat assistant (GPT-4)",
      "Real-time WebSocket data",
      "Priority support",
    ],
    cta: "Coming Soon",
    href: "#",
    popular: true,
    comingSoon: true,
  },
  {
    name: "Institutional",
    icon: Crown,
    price: { monthly: 199, annual: 159 },
    description: "For funds, prop desks, and professional traders.",
    color: "#f59e0b",
    features: [
      "Everything in Pro",
      "5 team seats",
      "API access for automation",
      "Custom AI model fine-tuning",
      "Dedicated account manager",
      "White-label option",
      "SLA guarantee",
      "Custom data integrations",
    ],
    cta: "Contact Sales",
    href: "#",
    popular: false,
    comingSoon: true,
  },
];

export default function Pricing() {
  const [annual, setAnnual] = useState(true);

  return (
    <section id="pricing" className="py-24 relative overflow-hidden">
      <div className="absolute inset-0"
        style={{ background: "radial-gradient(ellipse 60% 40% at 50% 100%, rgba(0,255,136,0.04) 0%, transparent 70%)" }} />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <div className="badge-green inline-flex mb-4">
            <Crown className="w-3 h-3" />
            <span>Transparent Pricing</span>
          </div>
          <h2 className="section-heading mb-4">
            Start free, upgrade when{" "}
            <span className="gradient-text-green">you&apos;re ready</span>
          </h2>
          <p className="section-subheading max-w-xl mx-auto mb-8">
            No hidden fees. Cancel anytime. Paid plans launching soon.
          </p>

          <div className="inline-flex items-center gap-3 p-1 rounded-xl border border-white/10 bg-white/5">
            <button onClick={() => setAnnual(false)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${!annual ? "bg-white/10 text-white" : "text-white/40"}`}>
              Monthly
            </button>
            <button onClick={() => setAnnual(true)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-all flex items-center gap-2 ${annual ? "bg-white/10 text-white" : "text-white/40"}`}>
              Annual
              <span className="badge-green text-[10px]">Save 20%</span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {plans.map((plan, i) => {
            const Icon = plan.icon;
            const price = annual ? plan.price.annual : plan.price.monthly;

            return (
              <div
                key={i}
                className={`glass-card p-6 relative transition-all duration-300 flex flex-col ${
                  plan.popular
                    ? "border-purple-500/30 shadow-glow-purple scale-[1.02]"
                    : plan.comingSoon
                    ? "opacity-60"
                    : "hover:border-white/10"
                }`}
              >
                {/* Coming Soon overlay */}
                {plan.comingSoon && (
                  <div className="absolute inset-0 rounded-2xl flex items-center justify-center z-10 pointer-events-none">
                    <div className="flex items-center gap-2 px-4 py-2 rounded-full border border-white/10"
                      style={{ background: "rgba(10,11,15,0.8)", backdropFilter: "blur(8px)" }}>
                      <Lock className="w-3.5 h-3.5 text-white/40" />
                      <span className="text-xs font-semibold text-white/50 uppercase tracking-wider">Coming Soon</span>
                    </div>
                  </div>
                )}

                {plan.popular && !plan.comingSoon && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full text-xs font-semibold"
                    style={{ background: "#8b5cf6", color: "#fff" }}>
                    Most Popular
                  </div>
                )}
                {plan.popular && plan.comingSoon && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full text-xs font-semibold bg-white/10 text-white/40">
                    Most Popular
                  </div>
                )}

                <div className="mb-6">
                  <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-4"
                    style={{ background: `${plan.color}15`, border: `1px solid ${plan.color}25` }}>
                    <Icon className="w-5 h-5" style={{ color: plan.color }} />
                  </div>
                  <h3 className="text-xl font-bold text-white mb-1">{plan.name}</h3>
                  <p className="text-sm text-white/40 leading-relaxed">{plan.description}</p>
                </div>

                <div className="mb-6">
                  {price === 0 ? (
                    <div><span className="text-4xl font-black text-white">Free</span></div>
                  ) : (
                    <div className="flex items-end gap-1">
                      <span className="text-4xl font-black text-white">${price}</span>
                      <span className="text-white/40 text-sm pb-1">/mo</span>
                    </div>
                  )}
                  {annual && price > 0 && (
                    <p className="text-xs text-white/30 mt-1">Billed annually (${price * 12}/yr)</p>
                  )}
                </div>

                <ul className="space-y-3 mb-8 flex-1">
                  {plan.features.map((feature, j) => (
                    <li key={j} className="flex items-start gap-2.5">
                      <Check className="w-4 h-4 mt-0.5 flex-shrink-0" style={{ color: plan.color }} />
                      <span className="text-sm text-white/60">{feature}</span>
                    </li>
                  ))}
                </ul>

                {plan.comingSoon ? (
                  <div className="w-full text-center py-3 rounded-xl font-semibold text-sm border border-white/10 text-white/30 cursor-not-allowed">
                    Coming Soon
                  </div>
                ) : (
                  <Link href={plan.href}
                    className={`w-full text-center py-3 rounded-xl font-semibold text-sm transition-all duration-200 ${plan.popular ? "btn-primary" : "btn-secondary"}`}
                    style={plan.popular ? {} : { borderColor: `${plan.color}20` }}>
                    {plan.cta}
                  </Link>
                )}
              </div>
            );
          })}
        </div>

        <p className="text-center text-xs text-white/20 mt-8">
          All plans include a 14-day money-back guarantee. No questions asked.
        </p>
      </div>
    </section>
  );
}
