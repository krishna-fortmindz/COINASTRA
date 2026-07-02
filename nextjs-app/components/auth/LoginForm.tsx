"use client";

import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { Eye, EyeOff, Mail, Lock, ArrowRight, Loader2 } from "lucide-react";
import { setTokens } from "@/lib/auth";

export default function LoginForm() {
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [toast, setToast] = useState(false);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const showToast = () => {
    setToast(true);
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(false), 3000);
  };

  useEffect(() => () => { if (toastTimer.current) clearTimeout(toastTimer.current); }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.message ?? "Invalid email or password");
        setLoading(false);
        return;
      }
      // Try every common backend response shape
      const d = data?.data ?? data;
      const accessToken =
        d?.accessToken ?? d?.access_token ?? d?.token ?? d?.jwt ??
        d?.tokens?.accessToken ?? d?.tokens?.access_token ?? d?.tokens?.access;
      const refreshToken =
        d?.refreshToken ?? d?.refresh_token ?? d?.refresh ??
        d?.tokens?.refreshToken ?? d?.tokens?.refresh_token ?? d?.tokens?.refresh;
      if (accessToken) {
        setTokens(String(accessToken), refreshToken ? String(refreshToken) : "");
      }
      const user = d?.user ?? d?.profile;
      if (user) {
        localStorage.setItem("coinastra_user", JSON.stringify(user));
      }
      const base = process.env.NEXT_PUBLIC_FLUTTER_DASHBOARD_URL ?? "http://localhost:8080";
      // replace() removes login from history so back-button goes to landing, not login
      window.location.replace(base === "http://localhost:8080" ? `${base}/dashboard` : "/app/");
    } catch {
      setError("Something went wrong. Please try again.");
      setLoading(false);
    }
  };

  return (
    <div className="space-y-5">
      {/* Toast */}
      <div
        className={`fixed top-5 left-1/2 -translate-x-1/2 z-50 px-4 py-2.5 rounded-xl text-xs font-medium text-white border border-white/10 bg-[#1a1c24] shadow-xl transition-all duration-300 pointer-events-none ${
          toast ? "opacity-100 translate-y-0" : "opacity-0 -translate-y-2"
        }`}
      >
        🚀 This feature will be live soon!
      </div>

      {/* Google */}
      <button
        type="button"
        onClick={showToast}
        className="w-full flex items-center justify-center gap-3 py-3 px-4 rounded-xl border border-white/10 bg-white/3 hover:bg-white/6 hover:border-white/15 transition-all text-sm font-medium text-white"
      >
        <svg className="w-4 h-4" viewBox="0 0 24 24">
          <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
          <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
          <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
          <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
        </svg>
        Continue with Google
      </button>

      <div className="flex items-center gap-3">
        <div className="flex-1 h-px bg-white/5" />
        <span className="text-xs text-white/20">or continue with email</span>
        <div className="flex-1 h-px bg-white/5" />
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="px-3 py-2.5 rounded-xl text-xs text-[#ff3366] border border-[#ff3366]/20 bg-[#ff3366]/5">
            {error}
          </div>
        )}

        {/* Email */}
        <div>
          <label className="block text-xs font-medium text-white/50 mb-1.5 uppercase tracking-wider">
            Email address
          </label>
          <div className="relative">
            <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-white/25" />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              required
              className="w-full bg-white/4 border border-white/8 rounded-xl pl-10 pr-4 py-3 text-sm text-white placeholder-white/20 focus:outline-none focus:border-[#00ff88]/30 focus:bg-white/6 transition-all"
            />
          </div>
        </div>

        {/* Password */}
        <div>
          <div className="flex items-center justify-between mb-1.5">
            <label className="text-xs font-medium text-white/50 uppercase tracking-wider">Password</label>
            <Link href="/auth/forgot-password" className="text-xs text-white/30 hover:text-[#00ff88] transition-colors">
              Forgot password?
            </Link>
          </div>
          <div className="relative">
            <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-white/25" />
            <input
              type={showPassword ? "text" : "password"}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              className="w-full bg-white/4 border border-white/8 rounded-xl pl-10 pr-12 py-3 text-sm text-white placeholder-white/20 focus:outline-none focus:border-[#00ff88]/30 focus:bg-white/6 transition-all"
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-white/25 hover:text-white/50 transition-colors"
            >
              {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
            </button>
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="btn-primary w-full py-3.5 text-sm disabled:opacity-60"
        >
          {loading ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <>
              Sign in
              <ArrowRight className="w-4 h-4" />
            </>
          )}
        </button>
      </form>

      <p className="text-center text-sm text-white/30">
        Don&apos;t have an account?{" "}
        <Link href="/auth/signup" className="text-[#00ff88] hover:text-[#00cc6a] font-medium transition-colors">
          Create one free
        </Link>
      </p>
    </div>
  );
}
