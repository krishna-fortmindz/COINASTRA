import { NextResponse } from "next/server";

export async function GET() {
  try {
    const base = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";
    const res = await fetch(
      `${base}/api/sentiment/social?symbol=BTCUSDT`,
      { next: { revalidate: 300 } }
    );
    if (!res.ok) throw new Error("upstream error");
    const data = await res.json();
    const fg = data?.fearAndGreed ?? data?.data?.fearAndGreed;
    if (fg?.value != null) return NextResponse.json(fg);
    return NextResponse.json({ value: 50, classification: "Neutral" });
  } catch {
    return NextResponse.json({ value: 50, classification: "Neutral" });
  }
}
