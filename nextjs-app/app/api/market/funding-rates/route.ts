import { NextResponse } from "next/server";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const base = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";
    const res = await fetch(`${base}/api/v1/dashboard/funding-rates`, {
      next: { revalidate: 30 },
    });
    if (!res.ok) throw new Error("upstream");
    const data = await res.json();
    const list = Array.isArray(data) ? data : data?.data ?? [];
    return NextResponse.json(list.slice(0, 8));
  } catch {
    return NextResponse.json([]);
  }
}
