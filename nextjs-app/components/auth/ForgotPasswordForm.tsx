"use client";

import { useState } from "react";
import Link from "next/link";
import { Mail, ArrowRight, Loader2, CheckCircle, ArrowLeft } from "lucide-react";

export default function ForgotPasswordForm() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/auth/forgot-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.message ?? "Failed to send reset code. Please try again.");
        setLoading(false);
        return;
      }
      setSent(true);
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  if (sent) {
    return (
      <div className="text-center space-y-4">
        <div className="w-12 h-12 rounded-full mx-auto flex items-center justify-center"
          style={{ background: "rgba(0,255,136,0.1)" }}>
          <CheckCircle className="w-6 h-6 text-[#00ff88]" />
        </div>
        <p className="text-sm text-white/60 leading-relaxed">
          A 6-digit reset code has been sent to{" "}
          <span className="text-white font-medium">{email}</span>.
          Check your inbox and enter it below.
        </p>
        <Link
          href={`/auth/verify-otp?email=${encodeURIComponent(email)}&type=password_reset`}
          className="btn-primary w-full text-sm py-3 flex items-center justify-center gap-2"
        >
          Enter OTP <ArrowRight className="w-4 h-4" />
        </Link>
        <Link href="/auth/login" className="flex items-center justify-center gap-2 text-sm text-white/30 hover:text-white/50 transition-colors">
          <ArrowLeft className="w-3.5 h-3.5" /> Back to sign in
        </Link>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="px-3 py-2.5 rounded-xl text-xs text-[#ff3366] border border-[#ff3366]/20 bg-[#ff3366]/5">
          {error}
        </div>
      )}

      <div>
        <label className="block text-xs font-medium text-white/50 mb-1.5 uppercase tracking-wider">Email address</label>
        <div className="relative">
          <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-white/25" />
          <input
            type="email" value={email} onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com" required
            className="w-full bg-white/4 border border-white/8 rounded-xl pl-10 pr-4 py-3 text-sm text-white placeholder-white/20 focus:outline-none focus:border-[#00ff88]/30 focus:bg-white/6 transition-all"
          />
        </div>
      </div>

      <button type="submit" disabled={loading} className="btn-primary w-full py-3.5 text-sm disabled:opacity-60">
        {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <>Send reset code <ArrowRight className="w-4 h-4" /></>}
      </button>

      <Link href="/auth/login" className="flex items-center justify-center gap-2 text-sm text-white/30 hover:text-white/60 transition-colors">
        <ArrowLeft className="w-3.5 h-3.5" /> Back to sign in
      </Link>
    </form>
  );
}
