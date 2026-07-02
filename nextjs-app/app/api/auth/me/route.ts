import { NextRequest, NextResponse } from "next/server";

const BACKEND_URL = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";

export async function GET(req: NextRequest) {
  const authorization = req.headers.get("authorization") ?? "";
  try {
    const res = await fetch(`${BACKEND_URL}/api/v1/auth/me`, {
      headers: { Authorization: authorization },
    });
    const data = await res.json();
    return NextResponse.json(data, { status: res.status });
  } catch {
    return NextResponse.json({ message: "Server error" }, { status: 500 });
  }
}
