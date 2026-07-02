import { NextRequest, NextResponse } from "next/server";

const BACKEND_URL = process.env.BACKEND_URL ?? "http://10.255.251.45:5000";

export async function POST(req: NextRequest) {
  try {
    const { email, otp } = await req.json();
    const res = await fetch(`${BACKEND_URL}/api/v1/auth/verify-otp`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, otp }),
    });
    const data = await res.json();
    return NextResponse.json(data, { status: res.status });
  } catch {
    return NextResponse.json({ message: "Server error" }, { status: 500 });
  }
}
