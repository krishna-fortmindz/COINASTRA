import { NextResponse } from "next/server";

export async function GET() {
  const base = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";
  try {
    const res = await fetch(`${base}/api/v1/dashboard/fear-greed`, {
      next: { revalidate: 300 },
    });
    if (!res.ok) throw new Error("upstream");
    const data = await res.json();
    const fg = data?.data ?? data;
    const value = Number(fg?.value ?? fg?.fgi?.value ?? 50);
    const classification = String(fg?.classification ?? fg?.fgi?.value_classification ?? "Neutral");
    return NextResponse.json({ value, classification });
  } catch {
    // Fallback: try sentiment social endpoint
    try {
      const res2 = await fetch(`${base}/api/sentiment/social?symbol=BTCUSDT`);
      if (res2.ok) {
        const d = await res2.json();
        const fg = d?.fearAndGreed ?? d?.data?.fearAndGreed;
        if (fg?.value != null) return NextResponse.json(fg);
      }
    } catch { }
    return NextResponse.json({ value: 50, classification: "Neutral" });
  }
}
