import type { Metadata } from "next";
import Link from "next/link";
import Navbar from "@/components/landing/Navbar";
import Footer from "@/components/landing/Footer";
import { Clock, Tag, ArrowRight } from "lucide-react";

const APP_URL = process.env.NEXT_PUBLIC_APP_URL || "https://coinastra.site";

export const metadata: Metadata = {
  title: "Blog — Crypto Market Analysis & Trading Intelligence",
  description:
    "In-depth crypto market analysis, trading psychology insights, and AI-powered intelligence reports from the Coinastra team. Learn to trade smarter.",
  alternates: { canonical: "/blog" },
  openGraph: {
    url: `${APP_URL}/blog`,
    type: "website",
    title: "Coinastra Blog — Crypto Intelligence Desk",
    description:
      "In-depth crypto market analysis, trading psychology, AI-powered intelligence reports, and risk management guides.",
  },
};

const posts = [
  {
    slug: "bitcoin-market-memory-oct-2024",
    title: "How the Market Memory Engine Predicted the October 2024 BTC Breakout",
    excerpt:
      "We detected an 87% structural match to the 2020 halving cycle 3 weeks before BTC broke $70K. Full analysis inside.",
    category: "Market Analysis",
    readTime: "8 min read",
    date: "Apr 28, 2026",
    dateISO: "2026-04-28",
    featured: true,
  },
  {
    slug: "crypto-sentiment-trading-guide",
    title: "Why Sentiment Data Beats Price Action for Entry Timing",
    excerpt: "Social and on-chain sentiment consistently leads price by 12–48 hours. Here's how to trade it.",
    category: "Education",
    readTime: "6 min read",
    date: "Apr 15, 2026",
    dateISO: "2026-04-15",
    featured: false,
  },
  {
    slug: "revenge-trading-ai-journal",
    title: "The Psychology Trap: How AI Caught My Revenge Trading Pattern",
    excerpt: "The AI Trade Journal identified a costly emotional pattern I didn't even know I had.",
    category: "Psychology",
    readTime: "5 min read",
    date: "Apr 3, 2026",
    dateISO: "2026-04-03",
    featured: false,
  },
  {
    slug: "new-listings-strategy-2026",
    title: "New Listings Alpha: Finding Early Momentum Before It Explodes",
    excerpt:
      "How to use whale accumulation signals and narrative strength to spot new listing opportunities.",
    category: "Strategy",
    readTime: "10 min read",
    date: "Mar 22, 2026",
    dateISO: "2026-03-22",
    featured: false,
  },
  {
    slug: "risk-management-crypto-2026",
    title: "The Only Risk Management Framework You'll Ever Need for Crypto",
    excerpt: "Position sizing, leverage limits, and liquidation avoidance — the complete guide.",
    category: "Risk Management",
    readTime: "12 min read",
    date: "Mar 10, 2026",
    dateISO: "2026-03-10",
    featured: false,
  },
  {
    slug: "rag-market-memory-technical",
    title: "How We Built the Market Memory Engine Using RAG",
    excerpt:
      "A technical deep-dive into our vector search system that matches current market states to historical patterns.",
    category: "Engineering",
    readTime: "15 min read",
    date: "Feb 28, 2026",
    dateISO: "2026-02-28",
    featured: false,
  },
];

const categoryColors: Record<string, string> = {
  "Market Analysis": "#00ff88",
  Education: "#8b5cf6",
  Psychology: "#ec4899",
  Strategy: "#06b6d4",
  "Risk Management": "#f59e0b",
  Engineering: "#3b82f6",
};

const blogSchema = {
  "@context": "https://schema.org",
  "@type": "Blog",
  "@id": `${APP_URL}/blog`,
  name: "Coinastra Intelligence Desk",
  description:
    "Market analysis, trading education, and AI-powered insights for serious crypto traders.",
  url: `${APP_URL}/blog`,
  inLanguage: "en-US",
  publisher: {
    "@id": `${APP_URL}/#organization`,
  },
  blogPost: posts.map((post) => ({
    "@type": "BlogPosting",
    headline: post.title,
    description: post.excerpt,
    url: `${APP_URL}/blog/${post.slug}`,
    datePublished: post.dateISO,
    dateModified: post.dateISO,
    articleSection: post.category,
    author: { "@id": `${APP_URL}/#organization` },
    publisher: { "@id": `${APP_URL}/#organization` },
    timeRequired: `PT${post.readTime.replace(" min read", "M")}`,
  })),
};

const breadcrumbSchema = {
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  itemListElement: [
    { "@type": "ListItem", position: 1, name: "Home", item: APP_URL },
    { "@type": "ListItem", position: 2, name: "Blog", item: `${APP_URL}/blog` },
  ],
};

export default function BlogPage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify([blogSchema, breadcrumbSchema]),
        }}
      />
      <main className="min-h-screen bg-[#0a0b0f]">
        <Navbar />
        <div className="pt-24 pb-24">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center mb-16 pt-8">
              <h1 className="text-4xl md:text-5xl font-black tracking-tight mb-4">
                <span className="gradient-text">Intelligence</span>{" "}
                <span className="gradient-text-green">Desk</span>
              </h1>
              <p className="text-lg text-white/40 max-w-xl mx-auto">
                Market analysis, trading education, and AI-powered insights for serious crypto traders.
              </p>
            </div>

            {/* Featured */}
            {posts.filter((p) => p.featured).map((post) => {
              const color = categoryColors[post.category];
              return (
                <Link
                  key={post.slug}
                  href={`/blog/${post.slug}`}
                  className="glass-card-hover p-8 mb-8 block group"
                >
                  <div className="flex items-center gap-3 mb-4">
                    <span className="badge-green text-xs">Featured</span>
                    <span
                      className="text-[10px] font-semibold px-2 py-1 rounded-full"
                      style={{
                        background: `${color}15`,
                        color,
                        border: `1px solid ${color}25`,
                      }}
                    >
                      <Tag className="w-2.5 h-2.5 inline mr-1" />
                      {post.category}
                    </span>
                  </div>
                  <h2 className="text-2xl md:text-3xl font-bold text-white mb-3 group-hover:text-[#00ff88] transition-colors leading-snug">
                    {post.title}
                  </h2>
                  <p className="text-white/50 leading-relaxed mb-4 max-w-2xl">{post.excerpt}</p>
                  <div className="flex items-center gap-4 text-xs text-white/25">
                    <span>{post.date}</span>
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {post.readTime}
                    </span>
                    <span className="text-[#00ff88] flex items-center gap-1 group-hover:gap-2 transition-all">
                      Read article <ArrowRight className="w-3 h-3" />
                    </span>
                  </div>
                </Link>
              );
            })}

            {/* Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {posts.filter((p) => !p.featured).map((post) => {
                const color = categoryColors[post.category];
                return (
                  <Link
                    key={post.slug}
                    href={`/blog/${post.slug}`}
                    className="glass-card-hover p-6 flex flex-col gap-4 group"
                  >
                    <span
                      className="text-[10px] font-semibold px-2 py-1 rounded-full self-start"
                      style={{
                        background: `${color}15`,
                        color,
                        border: `1px solid ${color}25`,
                      }}
                    >
                      {post.category}
                    </span>
                    <h3 className="text-base font-semibold text-white leading-snug group-hover:text-[#00ff88] transition-colors flex-1">
                      {post.title}
                    </h3>
                    <p className="text-sm text-white/40 leading-relaxed">{post.excerpt}</p>
                    <div className="flex items-center justify-between pt-3 border-t border-white/5">
                      <div className="flex items-center gap-3 text-xs text-white/25">
                        <span>{post.date}</span>
                        <span>{post.readTime}</span>
                      </div>
                      <ArrowRight className="w-3.5 h-3.5 text-white/20 group-hover:text-[#00ff88] transition-colors" />
                    </div>
                  </Link>
                );
              })}
            </div>
          </div>
        </div>
        <Footer />
      </main>
    </>
  );
}