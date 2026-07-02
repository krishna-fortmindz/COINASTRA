import { NextResponse } from "next/server";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const base = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";
    const res = await fetch(`${base}/api/v1/dashboard/trending`, {
      next: { revalidate: 60 },
    });
    if (!res.ok) throw new Error("upstream");
    const data = await res.json();
    const list = Array.isArray(data) ? data : data?.data ?? data?.coins ?? data?.trending ?? [];
    return NextResponse.json(list.slice(0, 10));
  } catch {
    return NextResponse.json([]);
  }
}
