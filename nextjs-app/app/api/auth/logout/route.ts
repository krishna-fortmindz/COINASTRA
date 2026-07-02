import { NextRequest, NextResponse } from "next/server";

const BACKEND_URL = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";

export async function POST(req: NextRequest) {
  const authorization = req.headers.get("authorization") ?? "";
  try {
    const res = await fetch(`${BACKEND_URL}/api/v1/auth/logout`, {
      method: "POST",
      headers: { Authorization: authorization, "Content-Type": "application/json" },
    });
    const data = await res.json().catch(() => ({}));
    return NextResponse.json(data, { status: res.status });
  } catch {
    return NextResponse.json({ message: "Server error" }, { status: 500 });
  }
}
