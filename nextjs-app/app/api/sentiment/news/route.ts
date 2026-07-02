import { NextResponse } from "next/server";

export async function GET() {
  try {
    const base = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";
    const res = await fetch(`${base}/api/sentiment/news`, {
      next: { revalidate: 120 },
    });
    if (!res.ok) throw new Error("upstream error");
    const data = await res.json();
    // Backend: { success, data: { averageNewsScore, status, articles: [...] } }
    const inner = data?.data ?? data;
    let articles: unknown[] = [];
    if (Array.isArray(inner?.articles)) articles = inner.articles;
    else if (Array.isArray(inner?.news)) articles = inner.news;
    else if (Array.isArray(inner)) articles = inner;
    else if (Array.isArray(data)) articles = data;
    return NextResponse.json(articles.slice(0, 6));
  } catch {
    return NextResponse.json([]);
  }
}
