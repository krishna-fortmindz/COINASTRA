import type { Metadata } from "next";
import Navbar from "@/components/landing/Navbar";
import LandingPageClient from "@/components/landing/LandingPageClient";
import Features from "@/components/landing/Features";
import PatternEngine from "@/components/landing/PatternEngine";
import SentimentDemo from "@/components/landing/SentimentDemo";
import Testimonials from "@/components/landing/Testimonials";
import FAQ from "@/components/landing/FAQ";
import BlogPreview from "@/components/landing/BlogPreview";
import CTASection from "@/components/landing/CTASection";
import Footer from "@/components/landing/Footer";

const APP_URL = process.env.NEXT_PUBLIC_APP_URL || "https://coinastra.site";

export const metadata: Metadata = {
  title: "Coinastra — AI-Powered Crypto Trading Intelligence",
  description:
    "Real-time AI analysis, live market data, sentiment signals, whale alerts, and risk management for serious crypto traders. Start free today.",
  alternates: { canonical: "/" },
  openGraph: {
    url: APP_URL,
    type: "website",
    title: "Coinastra — AI-Powered Crypto Trading Intelligence",
    description:
      "Real-time AI analysis, live market data, sentiment signals, whale alerts, and risk management for serious crypto traders.",
  },
};

const softwareAppSchema = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "@id": `${APP_URL}/#app`,
  name: "Coinastra",
  url: APP_URL,
  applicationCategory: "FinanceApplication",
  applicationSubCategory: "Cryptocurrency Trading Tools",
  operatingSystem: "Web, iOS, Android",
  description:
    "AI-powered crypto trading intelligence platform with real-time market analysis, sentiment signals, and risk management.",
  offers: [
    {
      "@type": "Offer",
      name: "Free Plan",
      price: "0",
      priceCurrency: "USD",
      description: "Basic market data and AI summaries",
    },
    {
      "@type": "Offer",
      name: "Pro Plan",
      price: "29",
      priceCurrency: "USD",
      billingIncrement: "month",
      description: "Full AI analysis, exchange connections, and advanced alerts",
    },
  ],
  aggregateRating: {
    "@type": "AggregateRating",
    ratingValue: "4.9",
    reviewCount: "12000",
    bestRating: "5",
    worstRating: "1",
  },
  featureList: [
    "AI Market Analysis",
    "Market Memory Engine — RAG-based historical pattern matching",
    "New Listings Intelligence",
    "Risk Management Calculator",
    "Sentiment Intelligence — Twitter, Reddit, on-chain",
    "AI Trade Journal with psychology insights",
    "Advanced Charts with AI overlays",
    "Smart Alert Center — whale alerts, funding rates",
    "AI Chat Assistant",
  ],
  screenshot: `${APP_URL}/opengraph-image`,
  publisher: {
    "@id": `${APP_URL}/#organization`,
  },
};

const faqSchema = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: [
    {
      "@type": "Question",
      name: "Is Coinastra a trading bot that places trades automatically?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "No. Coinastra is an intelligence and analysis platform, not an automated trading bot. It helps you make better decisions — it does not place trades on your behalf. You remain in full control.",
      },
    },
    {
      "@type": "Question",
      name: "How accurate is the Market Memory Engine?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "The engine uses semantic similarity matching on 10+ years of historical data. Similarity scores reflect structural pattern matching, not price predictions. Coinastra is transparent about confidence levels and always provides historical outcomes so you can judge for yourself.",
      },
    },
    {
      "@type": "Question",
      name: "What data sources does Coinastra use for sentiment analysis?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Coinastra aggregates Twitter/X (via official API), Reddit (top crypto subreddits), on-chain data (whale wallets, exchange flows), ETF inflow/outflow data, and curated news sources. All processed through AI for signal extraction.",
      },
    },
    {
      "@type": "Question",
      name: "Can I connect my exchange account to Coinastra?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Yes. On the Pro and Institutional plans, you can connect Binance, Bybit, OKX, and Coinbase via read-only API keys. Coinastra never requests withdrawal permissions — your funds are always safe.",
      },
    },
    {
      "@type": "Question",
      name: "Is the new coin listings feature real-time?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Yes. Coinastra monitors Binance and Bybit listing announcements 24/7 via WebSocket feeds. You'll receive alerts within seconds of a new listing going live, along with AI-generated analysis of potential momentum.",
      },
    },
    {
      "@type": "Question",
      name: "How does the AI Trade Journal work?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "You log your trades (entry, exit, size, emotion at time of trade). The AI analyzes patterns in your trading behavior — detecting things like revenge trading after losses, overtrading in volatile conditions, and suboptimal entry timing. It gives you weekly psychology reports.",
      },
    },
    {
      "@type": "Question",
      name: "What is Coinastra's refund policy?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "All paid plans include a 14-day money-back guarantee. If you're not satisfied for any reason, contact support within 14 days of your first payment for a full refund. No questions asked.",
      },
    },
    {
      "@type": "Question",
      name: "Does Coinastra offer an API for institutional clients?",
      acceptedAnswer: {
        "@type": "Answer",
        text: "Yes. The Institutional plan includes REST API access to Coinastra's AI analysis endpoints, sentiment scores, and market memory data. Contact the sales team for custom integrations and enterprise SLAs.",
      },
    },
  ],
};

export default function LandingPage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify([softwareAppSchema, faqSchema]),
        }}
      />
      <main className="min-h-screen bg-[#0a0b0f] overflow-x-hidden">
        <Navbar />
        <LandingPageClient />
        <Features />
        <PatternEngine />
        <SentimentDemo />
        <Testimonials />
        <FAQ />
        <BlogPreview />
        <CTASection />
        <Footer />
      </main>
    </>
  );
}
