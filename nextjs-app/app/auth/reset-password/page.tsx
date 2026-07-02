"use client";

import { useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { Eye, EyeOff, Lock, ArrowRight, Loader2, CheckCircle, Zap } from "lucide-react";

const passwordRequirements = [
  { label: "At least 8 characters", test: (p: string) => p.length >= 8 },
  { label: "Contains uppercase letter", test: (p: string) => /[A-Z]/.test(p) },
  { label: "Contains number", test: (p: string) => /\d/.test(p) },
];

function ResetPasswordContent() {
  const searchParams = useSearchParams();
  const email = searchParams.get("email") ?? "";

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }
    const allMet = passwordRequirements.every((r) => r.test(password));
    if (!allMet) {
      setError("Password does not meet the requirements.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/auth/reset-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.message ?? "Failed to reset password. Please try again.");
        setLoading(false);
        return;
      }
      setDone(true);
    } catch {
      setError("Something went wrong. Please try again.");
      setLoading(false);
    }
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
          <div className="glass-card p-8">
            {done ? (
              <div className="text-center space-y-4">
                <div className="w-12 h-12 rounded-full mx-auto flex items-center justify-center"
                  style={{ background: "rgba(0,255,136,0.1)" }}>
                  <CheckCircle className="w-6 h-6 text-[#00ff88]" />
                </div>
                <h2 className="text-xl font-bold text-white">Password reset!</h2>
                <p className="text-sm text-white/40">Your password has been updated. You can now sign in.</p>
                <Link href="/auth/login" className="btn-primary w-full text-sm py-3 flex items-center justify-center gap-2">
                  Go to sign in <ArrowRight className="w-4 h-4" />
                </Link>
              </div>
            ) : (
              <>
                <div className="mb-6">
                  <h1 className="text-2xl font-bold text-white mb-2">Create new password</h1>
                  <p className="text-sm text-white/40">Enter your new password below.</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-4">
                  {error && (
                    <div className="px-3 py-2.5 rounded-xl text-xs text-[#ff3366] border border-[#ff3366]/20 bg-[#ff3366]/5">
                      {error}
                    </div>
                  )}

                  <div>
                    <label className="block text-xs font-medium text-white/50 mb-1.5 uppercase tracking-wider">New password</label>
                    <div className="relative">
                      <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-white/25" />
                      <input
                        type={showPassword ? "text" : "password"}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="Create a strong password"
                        required
                        className="w-full bg-white/4 border border-white/8 rounded-xl pl-10 pr-12 py-3 text-sm text-white placeholder-white/20 focus:outline-none focus:border-[#00ff88]/30 focus:bg-white/6 transition-all"
                      />
                      <button type="button" onClick={() => setShowPassword(!showPassword)}
                        className="absolute right-3.5 top-1/2 -translate-y-1/2 text-white/25 hover:text-white/50 transition-colors">
                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>

                    {password && (
                      <div className="mt-2 space-y-1.5">
                        {passwordRequirements.map((req, i) => {
                          const met = req.test(password);
                          return (
                            <div key={i} className={`flex items-center gap-2 text-xs transition-colors ${met ? "text-[#00ff88]" : "text-white/25"}`}>
                              <div className={`w-1.5 h-1.5 rounded-full ${met ? "bg-[#00ff88]" : "bg-white/20"}`} />
                              {req.label}
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>

                  <div>
                    <label className="block text-xs font-medium text-white/50 mb-1.5 uppercase tracking-wider">Confirm password</label>
                    <div className="relative">
                      <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-white/25" />
                      <input
                        type={showConfirm ? "text" : "password"}
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        placeholder="Repeat your password"
                        required
                        className="w-full bg-white/4 border border-white/8 rounded-xl pl-10 pr-12 py-3 text-sm text-white placeholder-white/20 focus:outline-none focus:border-[#00ff88]/30 focus:bg-white/6 transition-all"
                      />
                      <button type="button" onClick={() => setShowConfirm(!showConfirm)}
                        className="absolute right-3.5 top-1/2 -translate-y-1/2 text-white/25 hover:text-white/50 transition-colors">
                        {showConfirm ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>

                  <button type="submit" disabled={loading} className="btn-primary w-full py-3.5 text-sm disabled:opacity-60">
                    {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <>Set new password <ArrowRight className="w-4 h-4" /></>}
                  </button>
                </form>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function ResetPasswordPage() {
  return (
    <Suspense>
      <ResetPasswordContent />
    </Suspense>
  );
}
