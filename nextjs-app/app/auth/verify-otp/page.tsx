"use client";

import { useState, useRef, useEffect, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { Loader2, CheckCircle, ArrowLeft, Zap } from "lucide-react";
import { setTokens } from "@/lib/auth";

function VerifyOTPContent() {
  const searchParams = useSearchParams();
  const email = searchParams.get("email") ?? "";
  const type = (searchParams.get("type") ?? "email_verification") as "email_verification" | "password_reset";

  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [verified, setVerified] = useState(false);
  const [error, setError] = useState("");
  const refs = useRef<(HTMLInputElement | null)[]>([]);

  const handleChange = (i: number, val: string) => {
    if (!/^\d?$/.test(val)) return;
    const next = [...otp];
    next[i] = val;
    setOtp(next);
    if (val && i < 5) refs.current[i + 1]?.focus();
  };

  const handleKeyDown = (i: number, e: React.KeyboardEvent) => {
    if (e.key === "Backspace" && !otp[i] && i > 0) refs.current[i - 1]?.focus();
  };

  const handleVerify = async () => {
    const code = otp.join("");
    if (code.length < 6) return;
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/auth/verify-otp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, otp: code, type }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.message ?? "Invalid or expired code. Please try again.");
        setLoading(false);
        return;
      }

      if (type === "email_verification") {
        const d = data?.data ?? data;
        const accessToken =
          d?.accessToken ?? d?.access_token ?? d?.token ?? d?.jwt ??
          d?.tokens?.accessToken ?? d?.tokens?.access_token;
        const refreshToken =
          d?.refreshToken ?? d?.refresh_token ?? d?.refresh ??
          d?.tokens?.refreshToken ?? d?.tokens?.refresh_token;
        if (accessToken) setTokens(String(accessToken), refreshToken ? String(refreshToken) : "");
        const user = d?.user ?? d?.profile;
        if (user) localStorage.setItem("coinastra_user", JSON.stringify(user));
        setVerified(true);
        setTimeout(() => {
          const base = process.env.NEXT_PUBLIC_FLUTTER_DASHBOARD_URL ?? "http://localhost:8080";
          window.location.replace(base === "http://localhost:8080" ? `${base}/dashboard` : "/app/");
        }, 1500);
      } else {
        // password_reset — OTP verified server-side, just pass email
        window.location.replace(`/auth/reset-password?email=${encodeURIComponent(email)}`);
      }
    } catch {
      setError("Something went wrong. Please try again.");
      setLoading(false);
    }
  };

  const handleResend = async () => {
    if (!email) return;
    setResending(true);
    setError("");
    try {
      await fetch("/api/auth/resend-otp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
    } catch {}
    setResending(false);
  };

  return (
    <div className="min-h-screen bg-[#0a0b0f] flex flex-col">
      <div className="fixed inset-0 grid-bg opacity-40 pointer-events-none" />
      <div className="fixed inset-0 pointer-events-none"
        style={{ background: "radial-gradient(ellipse 60% 40% at 50% 0%, rgba(0,255,136,0.06) 0%, transparent 60%)" }} />

      <nav className="relative z-10 flex items-center px-6 py-4">
        <Link href="/" className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-lg flex items-center justify-center"
            style={{ background: "linear-gradient(135deg, #00ff88, #00cc6a)" }}>
            <Zap className="w-3.5 h-3.5 text-black" strokeWidth={2.5} />
          </div>
          <span className="text-sm font-bold text-white">AI Trading <span style={{ color: "#00ff88" }}>Copilot</span></span>
        </Link>
      </nav>

      <div className="relative z-10 flex-1 flex items-center justify-center px-4">
        <div className="w-full max-w-md">
          <div className="glass-card p-8 text-center">
            {verified ? (
              <div className="space-y-4">
                <div className="w-12 h-12 rounded-full mx-auto flex items-center justify-center"
                  style={{ background: "rgba(0,255,136,0.1)" }}>
                  <CheckCircle className="w-6 h-6 text-[#00ff88]" />
                </div>
                <h2 className="text-xl font-bold text-white">Account verified!</h2>
                <p className="text-sm text-white/40">Redirecting to your dashboard…</p>
              </div>
            ) : (
              <>
                <div className="mb-6">
                  <h1 className="text-2xl font-bold text-white mb-2">
                    {type === "password_reset" ? "Reset your password" : "Verify your email"}
                  </h1>
                  <p className="text-sm text-white/40">
                    We sent a 6-digit code to{" "}
                    {email ? <span className="text-white/60">{email}</span> : "your email address"}
                  </p>
                  <p className="text-xs text-white/30 mt-2 flex items-center justify-center gap-1.5">
                    <span className="inline-block w-1.5 h-1.5 rounded-full bg-[#00ff88]" />
                    Sent successfully &mdash; check your spam if you don&apos;t see it
                  </p>
                </div>

                {error && (
                  <div className="mb-4 px-3 py-2.5 rounded-xl text-xs text-[#ff3366] border border-[#ff3366]/20 bg-[#ff3366]/5">
                    {error}
                  </div>
                )}

                <div className="flex items-center justify-center gap-2 mb-6">
                  {otp.map((digit, i) => (
                    <input
                      key={i}
                      ref={(el) => { refs.current[i] = el; }}
                      type="text" inputMode="numeric" maxLength={1}
                      value={digit} onChange={(e) => handleChange(i, e.target.value)}
                      onKeyDown={(e) => handleKeyDown(i, e)}
                      className="w-11 h-13 text-center text-lg font-bold font-mono bg-white/4 border border-white/8 rounded-xl text-white focus:outline-none focus:border-[#00ff88]/40 focus:bg-white/6 transition-all"
                      style={{ caretColor: "#00ff88" }}
                    />
                  ))}
                </div>

                <button
                  onClick={handleVerify}
                  disabled={loading || otp.join("").length < 6}
                  className="btn-primary w-full py-3.5 text-sm disabled:opacity-50 mb-4"
                >
                  {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : (
                    type === "password_reset" ? "Continue to Reset" : "Verify Account"
                  )}
                </button>

                <p className="text-sm text-white/30">
                  Didn&apos;t receive the code?{" "}
                  <button
                    onClick={handleResend}
                    disabled={resending}
                    className="text-[#00ff88] hover:text-[#00cc6a] font-medium transition-colors disabled:opacity-50"
                  >
                    {resending ? "Sending…" : "Resend"}
                  </button>
                </p>

                <Link href="/auth/login"
                  className="flex items-center justify-center gap-2 text-sm text-white/20 hover:text-white/40 transition-colors mt-4">
                  <ArrowLeft className="w-3.5 h-3.5" /> Back to sign in
                </Link>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function VerifyOTPPage() {
  return (
    <Suspense>
      <VerifyOTPContent />
    </Suspense>
  );
}
