import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import Navbar from "@/components/landing/Navbar";
import Footer from "@/components/landing/Footer";
import { Clock, Tag, ArrowLeft, ArrowRight } from "lucide-react";
import { getPostBySlug, getAllSlugs, getAllPosts } from "@/lib/blog";

const APP_URL = process.env.NEXT_PUBLIC_APP_URL || "https://coinastra.site";

const categoryColors: Record<string, string> = {
  "Market Analysis": "#00ff88",
  Education: "#8b5cf6",
  Psychology: "#ec4899",
  Strategy: "#06b6d4",
  "Risk Management": "#f59e0b",
  Engineering: "#3b82f6",
};

export async function generateStaticParams() {
  return getAllSlugs().map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: { slug: string };
}): Promise<Metadata> {
  const post = getPostBySlug(params.slug);
  if (!post) return {};

  return {
    title: `${post.title} — Coinastra Blog`,
    description: post.excerpt,
    alternates: { canonical: `/blog/${post.slug}` },
    openGraph: {
      url: `${APP_URL}/blog/${post.slug}`,
      type: "article",
      title: post.title,
      description: post.excerpt,
      publishedTime: post.dateISO,
    },
  };
}

export default function BlogPostPage({ params }: { params: { slug: string } }) {
  const post = getPostBySlug(params.slug);
  if (!post) notFound();

  const allPosts = getAllPosts();
  const currentIndex = allPosts.findIndex((p) => p.slug === post.slug);
  const prevPost = currentIndex < allPosts.length - 1 ? allPosts[currentIndex + 1] : null;
  const nextPost = currentIndex > 0 ? allPosts[currentIndex - 1] : null;

  const color = categoryColors[post.category] || "#00ff88";

  const articleSchema = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    headline: post.title,
    description: post.excerpt,
    url: `${APP_URL}/blog/${post.slug}`,
    datePublished: post.dateISO,
    dateModified: post.dateISO,
    articleSection: post.category,
    author: {
      "@type": "Organization",
      name: post.author,
      url: APP_URL,
    },
    publisher: {
      "@id": `${APP_URL}/#organization`,
    },
    mainEntityOfPage: `${APP_URL}/blog/${post.slug}`,
  };

  const breadcrumbSchema = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Home", item: APP_URL },
      { "@type": "ListItem", position: 2, name: "Blog", item: `${APP_URL}/blog` },
      { "@type": "ListItem", position: 3, name: post.title, item: `${APP_URL}/blog/${post.slug}` },
    ],
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify([articleSchema, breadcrumbSchema]),
        }}
      />
      <main className="min-h-screen bg-[#0a0b0f]">
        <Navbar />
        <div className="pt-24 pb-24">
          <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
            {/* Back link */}
            <Link
              href="/blog"
              className="inline-flex items-center gap-2 text-sm text-white/30 hover:text-white/70 transition-colors mb-10 group"
            >
              <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
              Back to Intelligence Desk
            </Link>

            {/* Header */}
            <div className="mb-10 pt-4">
              <span
                className="inline-flex items-center gap-1 text-[10px] font-semibold uppercase tracking-wider px-2 py-1 rounded-full mb-4"
                style={{
                  background: `${color}15`,
                  color,
                  border: `1px solid ${color}25`,
                }}
              >
                <Tag className="w-2.5 h-2.5" />
                {post.category}
              </span>

              <h1 className="text-3xl md:text-4xl font-black text-white leading-tight mb-4">
                {post.title}
              </h1>

              <p className="text-lg text-white/50 leading-relaxed mb-6">{post.excerpt}</p>

              <div className="flex items-center gap-4 text-sm text-white/25 pb-8 border-b border-white/5">
                <span>{post.author}</span>
                <span className="w-1 h-1 rounded-full bg-white/20" />
                <span>{post.date}</span>
                <span className="w-1 h-1 rounded-full bg-white/20" />
                <span className="flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5" />
                  {post.readTime}
                </span>
              </div>
            </div>

            {/* Article content */}
            <article
              className="prose-blog"
              dangerouslySetInnerHTML={{ __html: post.content }}
            />

            {/* Prev / Next navigation */}
            <div className="mt-16 pt-8 border-t border-white/5 grid grid-cols-1 sm:grid-cols-2 gap-4">
              {prevPost && (
                <Link
                  href={`/blog/${prevPost.slug}`}
                  className="glass-card-hover p-5 flex flex-col gap-2 group"
                >
                  <span className="text-xs text-white/25 flex items-center gap-1">
                    <ArrowLeft className="w-3 h-3" /> Previous
                  </span>
                  <span className="text-sm font-semibold text-white group-hover:text-[#00ff88] transition-colors leading-snug">
                    {prevPost.title}
                  </span>
                </Link>
              )}
              {nextPost && (
                <Link
                  href={`/blog/${nextPost.slug}`}
                  className="glass-card-hover p-5 flex flex-col gap-2 group sm:text-right sm:col-start-2"
                >
                  <span className="text-xs text-white/25 flex items-center gap-1 sm:justify-end">
                    Next <ArrowRight className="w-3 h-3" />
                  </span>
                  <span className="text-sm font-semibold text-white group-hover:text-[#00ff88] transition-colors leading-snug">
                    {nextPost.title}
                  </span>
                </Link>
              )}
            </div>
          </div>
        </div>
        <Footer />
      </main>
    </>
  );
}
