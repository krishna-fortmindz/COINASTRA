import type { Metadata } from "next";
import Link from "next/link";
import Navbar from "@/components/landing/Navbar";
import Footer from "@/components/landing/Footer";
import {
  Zap,
  Brain,
  Shield,
  TrendingUp,
  Globe,
  Lock,
  BarChart2,
  BookOpen,
  Mail,
  MessageCircle,
} from "lucide-react";

const APP_URL = process.env.NEXT_PUBLIC_APP_URL || "https://coinastra.site";

export const metadata: Metadata = {
  title: "About Coinastra — AI-Powered Crypto Trading Intelligence",
  description:
    "Learn about Coinastra's mission to democratize AI-powered crypto trading intelligence. Built by traders and ML engineers to give every trader an edge through real-time sentiment, pattern recognition, and risk management.",
  alternates: { canonical: "/about" },
  openGraph: {
    url: `${APP_URL}/about`,
    type: "website",
    title: "About Coinastra — Who We Are & How It Works",
    description:
      "Coinastra is an AI-powered crypto intelligence platform built by traders for traders. Real-time sentiment, whale alerts, and risk management — all in one place.",
  },
};

const aboutSchema = {
  "@context": "https://schema.org",
  "@type": "AboutPage",
  "@id": `${APP_URL}/about#webpage`,
  url: `${APP_URL}/about`,
  name: "About Coinastra",
  description:
    "Coinastra is an AI-powered cryptocurrency trading intelligence platform built to give serious traders an edge through real-time market analysis, sentiment signals, and risk management tools.",
  isPartOf: { "@id": `${APP_URL}/#website` },
  about: { "@id": `${APP_URL}/#organization` },
  breadcrumb: {
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Home", item: APP_URL },
      { "@type": "ListItem", position: 2, name: "About", item: `${APP_URL}/about` },
    ],
  },
};

const values = [
  {
    icon: Brain,
    title: "AI-First Intelligence",
    body: "Every insight is powered by machine learning models trained on millions of market events, not hand-crafted rules. Our models update continuously as markets evolve.",
  },
  {
    icon: Shield,
    title: "Risk Before Reward",
    body: "Position sizing, drawdown limits, and real-time risk scoring are core to the platform — not an afterthought. We believe protecting capital is the foundation of consistent returns.",
  },
  {
    icon: Lock,
    title: "Transparent by Design",
    body: "We publish our AI methodology, show confidence intervals on every signal, and never hide how conclusions are reached. You should understand what drives your edge.",
  },
  {
    icon: Globe,
    title: "Data Without Borders",
    body: "We aggregate on-chain activity, social sentiment, exchange order flow, and macro signals across 50+ sources so you don't have to monitor 20 tabs to understand a market.",
  },
];

const howItWorks = [
  {
    step: "01",
    title: "Multi-Source Data Ingestion",
    body: "We pull real-time data from exchange websockets, on-chain analytics providers, social platforms, and news feeds — normalised into a unified time-series store updated tick by tick.",
  },
  {
    step: "02",
    title: "AI Signal Generation",
    body: "Our NLP models score news and social content for sentiment, our pattern-recognition engine matches current price action against a historical library of 10,000+ patterns, and our whale-detection layer flags unusual order flow within seconds.",
  },
  {
    step: "03",
    title: "Market Memory (RAG Engine)",
    body: "A retrieval-augmented generation system indexes every significant market event since 2018. When conditions today resemble a past event, the engine surfaces comparable setups and their outcomes — giving you structural context, not just price data.",
  },
  {
    step: "04",
    title: "Risk-Adjusted Outputs",
    body: "Every signal is passed through a risk layer that calculates suggested position size, stop-loss levels, and expected drawdown given your account parameters before anything is shown on the dashboard.",
  },
];

const stats = [
  { value: "50+", label: "Data sources monitored" },
  { value: "10k+", label: "Historical patterns indexed" },
  { value: "200ms", label: "Median signal latency" },
  { value: "Free", label: "Core tier, always" },
];

export default function AboutPage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(aboutSchema) }}
      />
      <Navbar />

      <main className="min-h-screen bg-[#0a0b0f]">
        {/* Hero */}
        <section className="relative pt-28 pb-20 overflow-hidden">
          <div className="absolute inset-0 grid-bg opacity-15" />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full bg-[#00ff88]/3 blur-[120px] pointer-events-none" />
          <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-white/10 bg-white/5 mb-6">
              <Zap className="w-3.5 h-3.5 text-[#00ff88]" />
              <span className="text-xs text-white/60 font-mono uppercase tracking-wider">About Coinastra</span>
            </div>
            <h1 className="text-4xl sm:text-5xl font-extrabold text-white leading-tight mb-6">
              Intelligence built for<br />
              <span style={{ color: "#00ff88" }}>serious traders</span>
            </h1>
            <p className="text-lg text-white/50 leading-relaxed max-w-2xl mx-auto">
              Coinastra is an AI-powered cryptocurrency trading intelligence platform that aggregates
              sentiment, order flow, on-chain data, and historical patterns into a single, actionable
              dashboard — so you stop guessing and start trading with structural edge.
            </p>
          </div>
        </section>

        {/* Stats */}
        <section className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 pb-16">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            {stats.map(({ value, label }) => (
              <div key={label} className="glass-card p-6 text-center">
                <div className="text-3xl font-extrabold font-mono text-[#00ff88] mb-1">{value}</div>
                <div className="text-xs text-white/40 leading-snug">{label}</div>
              </div>
            ))}
          </div>
        </section>

        {/* Mission */}
        <section className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 pb-20">
          <div className="glass-card p-8 sm:p-12">
            <h2 className="text-2xl font-bold text-white mb-4">Why we built this</h2>
            <div className="space-y-4 text-white/55 leading-relaxed">
              <p>
                Most retail crypto traders operate at a systematic disadvantage. Institutional desks
                have quant teams, order-flow data, and proprietary sentiment feeds. Individual traders
                have charts, Twitter, and gut feel.
              </p>
              <p>
                We built Coinastra to close that gap. By combining large-language models for news
                analysis, retrieval-augmented generation for historical pattern matching, and real-time
                exchange websocket data, we can surface the same quality of market intelligence that
                previously required a full quant infrastructure — accessible in a browser, for free.
              </p>
              <p>
                The platform is not a trading bot and does not execute trades on your behalf.
                It is an intelligence layer: it processes information faster and more comprehensively
                than any individual can, then presents that information clearly so you can make
                better-informed decisions with your own capital.
              </p>
            </div>
          </div>
        </section>

        {/* Values */}
        <section className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 pb-20">
          <h2 className="text-2xl font-bold text-white mb-8 text-center">What we stand for</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {values.map(({ icon: Icon, title, body }) => (
              <div key={title} className="glass-card p-6 flex gap-4">
                <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-[#00ff88]/10 flex items-center justify-center">
                  <Icon className="w-5 h-5 text-[#00ff88]" />
                </div>
                <div>
                  <h3 className="font-semibold text-white mb-1.5">{title}</h3>
                  <p className="text-sm text-white/45 leading-relaxed">{body}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* How it works */}
        <section className="relative py-20">
          <div className="absolute inset-0 grid-bg opacity-10" />
          <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center mb-12">
              <h2 className="text-2xl font-bold text-white mb-3">How the AI works</h2>
              <p className="text-white/40 max-w-xl mx-auto text-sm">
                Four processing stages turn raw market noise into structured trading intelligence.
              </p>
            </div>
            <div className="space-y-4">
              {howItWorks.map(({ step, title, body }) => (
                <div key={step} className="glass-card p-6 flex gap-6 items-start">
                  <div className="flex-shrink-0 text-3xl font-extrabold font-mono text-[#00ff88]/20 leading-none pt-0.5">
                    {step}
                  </div>
                  <div>
                    <h3 className="font-semibold text-white mb-1.5">{title}</h3>
                    <p className="text-sm text-white/45 leading-relaxed">{body}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Platform transparency */}
        <section className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
          <h2 className="text-2xl font-bold text-white mb-8 text-center">Platform transparency</h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="glass-card p-6">
              <BarChart2 className="w-6 h-6 text-[#00ff88] mb-3" />
              <h3 className="font-semibold text-white mb-2 text-sm">No Hidden Signals</h3>
              <p className="text-xs text-white/40 leading-relaxed">
                Every AI signal shows its data sources, confidence level, and the specific conditions
                that triggered it. You can always trace why a recommendation appeared.
              </p>
            </div>
            <div className="glass-card p-6">
              <BookOpen className="w-6 h-6 text-[#00ff88] mb-3" />
              <h3 className="font-semibold text-white mb-2 text-sm">Not Financial Advice</h3>
              <p className="text-xs text-white/40 leading-relaxed">
                Coinastra is an information tool. All outputs are analytical summaries of market data.
                They are not personalised financial advice and should not be treated as investment recommendations.
              </p>
            </div>
            <div className="glass-card p-6">
              <TrendingUp className="w-6 h-6 text-[#00ff88] mb-3" />
              <h3 className="font-semibold text-white mb-2 text-sm">No Guaranteed Returns</h3>
              <p className="text-xs text-white/40 leading-relaxed">
                Past pattern matches do not guarantee future results. Crypto markets are volatile and
                unpredictable. Always use appropriate position sizing and risk management.
              </p>
            </div>
          </div>
        </section>

        {/* Contact */}
        <section className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 pb-24">
          <div className="glass-card p-8 sm:p-12 text-center">
            <h2 className="text-2xl font-bold text-white mb-3">Get in touch</h2>
            <p className="text-white/45 mb-8 max-w-md mx-auto text-sm leading-relaxed">
              Questions about the platform, press enquiries, or partnership discussions — we read
              every message and aim to respond within one business day.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <a
                href="mailto:support@coinastra.site"
                className="btn-primary flex items-center gap-2 text-sm"
              >
                <Mail className="w-4 h-4" />
                support@coinastra.site
              </a>
              <a
                href="https://discord.gg/coinastra"
                target="_blank"
                rel="noopener noreferrer"
                className="btn-secondary flex items-center gap-2 text-sm"
              >
                <MessageCircle className="w-4 h-4" />
                Join our Discord
              </a>
            </div>
            <p className="text-xs text-white/20 mt-8">
              Coinastra is operated by Fortmindz Technologies. All data is processed in compliance
              with applicable privacy regulations. See our{" "}
              <Link href="/privacy" className="underline hover:text-white/40 transition-colors">
                Privacy Policy
              </Link>{" "}
              for details.
            </p>
          </div>
        </section>
      </main>

      <Footer />
    </>
  );
}
