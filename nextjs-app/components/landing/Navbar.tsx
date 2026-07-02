"use client";
import { useState, useEffect } from "react";
import Link from "next/link";
import { Menu, X, Zap, ExternalLink } from "lucide-react";

const FLUTTER_BASE =
  process.env.NEXT_PUBLIC_FLUTTER_DASHBOARD_URL ?? "http://localhost:8080";
const DASHBOARD_URL = process.env.NEXT_PUBLIC_FLUTTER_DASHBOARD_URL
  ? "/app/"
  : `${FLUTTER_BASE}/dashboard`;

const navLinks = [
  { label: "Features",      href: "/#features"      },
  { label: "Market Memory", href: "/#memory-engine" },
  { label: "Blog",          href: "/blog"           },
];

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [authMounted, setAuthMounted] = useState(false);

  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handler, { passive: true });
    return () => window.removeEventListener("scroll", handler);
  }, []);

  useEffect(() => {
    const token = localStorage.getItem("coinastra_access");
    setIsLoggedIn(!!token);
    setAuthMounted(true);
  }, []);

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled
          ? "bg-[#0a0b0f]/90 backdrop-blur-xl border-b border-white/5 shadow-[0_4px_24px_rgba(0,0,0,0.4)]"
          : "bg-transparent"
      }`}
    >
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2.5 group">
            <div
              className="w-8 h-8 rounded-lg flex items-center justify-center relative overflow-hidden"
              style={{ background: "linear-gradient(135deg, #00ff88, #00cc6a)" }}
            >
              <Zap className="w-4 h-4 text-black" strokeWidth={2.5} />
            </div>
            <div>
              <span className="text-sm font-bold text-white tracking-tight">Coin</span>
              <span className="text-sm font-bold tracking-tight" style={{ color: "#00ff88" }}>astra</span>
            </div>
          </Link>

          {/* Desktop Nav */}
          <div className="hidden md:flex items-center gap-1">
            {navLinks.map((link) => (
              <Link
                key={link.label}
                href={link.href}
                className="px-4 py-2 text-sm text-white/60 hover:text-white rounded-lg hover:bg-white/5 transition-all font-medium"
              >
                {link.label}
              </Link>
            ))}
          </div>

          {/* Auth CTAs */}
          <div className="hidden md:flex items-center gap-2.5 min-w-[180px] justify-end">
            {!authMounted ? null : isLoggedIn ? (
              <a href={DASHBOARD_URL} className="btn-primary text-sm px-5 py-2.5 flex items-center gap-2">
                Open Dashboard
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            ) : (
              <>
                <Link
                  href="/auth/login"
                  className="px-4 py-2.5 text-sm font-medium text-white/70 hover:text-white rounded-xl border border-white/10 hover:border-white/20 hover:bg-white/5 transition-all"
                >
                  Sign In
                </Link>
                <Link
                  href="/auth/signup"
                  className="btn-primary text-sm px-5 py-2.5"
                >
                  Sign Up Free
                </Link>
              </>
            )}
          </div>

          {/* Mobile toggle */}
          <button
            className="md:hidden p-2 rounded-lg text-white/60 hover:text-white hover:bg-white/5 transition-all"
            onClick={() => setMobileOpen(!mobileOpen)}
          >
            {mobileOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </nav>

      {/* Mobile menu */}
      {mobileOpen && (
        <div className="md:hidden bg-[#0f1117]/95 backdrop-blur-xl border-b border-white/5">
          <div className="max-w-7xl mx-auto px-4 py-4 space-y-1">
            {navLinks.map((link) => (
              <Link
                key={link.label}
                href={link.href}
                className="block px-4 py-3 text-sm text-white/70 hover:text-white hover:bg-white/5 rounded-xl transition-all"
                onClick={() => setMobileOpen(false)}
              >
                {link.label}
              </Link>
            ))}
            <div className="pt-3 border-t border-white/5 space-y-2">
              {!authMounted ? null : isLoggedIn ? (
                <a href={DASHBOARD_URL} className="btn-primary block text-center text-sm">
                  Open Dashboard
                </a>
              ) : (
                <>
                  <Link
                    href="/auth/login"
                    className="block text-center px-4 py-3 text-sm font-medium text-white/70 border border-white/10 rounded-xl hover:bg-white/5 transition-all"
                    onClick={() => setMobileOpen(false)}
                  >
                    Sign In
                  </Link>
                  <Link
                    href="/auth/signup"
                    className="btn-primary block text-center text-sm"
                    onClick={() => setMobileOpen(false)}
                  >
                    Sign Up Free
                  </Link>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
