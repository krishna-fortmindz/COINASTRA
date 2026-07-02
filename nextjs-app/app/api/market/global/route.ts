import { NextResponse } from "next/server";

export async function GET() {
  try {
    const base = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";
    const res = await fetch(`${base}/api/v1/dashboard/global`, {
      next: { revalidate: 120 },
    });
    if (!res.ok) throw new Error("upstream");
    const data = await res.json();
    return NextResponse.json(data?.data ?? data);
  } catch {
    return NextResponse.json(null);
  }
}
