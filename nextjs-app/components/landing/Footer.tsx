import Link from "next/link";
import { Zap, Twitter, Github, MessageCircle } from "lucide-react";

const FLUTTER_BASE =
  process.env.NEXT_PUBLIC_FLUTTER_DASHBOARD_URL ?? "http://localhost:8080";

const footerLinks = {
  Product: [
    { label: "Dashboard",    href: `${FLUTTER_BASE}/dashboard` },
    { label: "AI Analysis",  href: `${FLUTTER_BASE}/analysis` },
    { label: "Market Memory",href: `${FLUTTER_BASE}/charts` },
    { label: "Sentiment",    href: `${FLUTTER_BASE}/sentiment` },
    { label: "AI Chat",      href: `${FLUTTER_BASE}/chat` },
  ],
  Company: [
    { label: "About",    href: "/about" },
    { label: "Blog",     href: "/blog" },
    { label: "Careers",  href: "/careers" },
    { label: "Contact",  href: "/contact" },
    { label: "Status",   href: "https://status.coinastra.site" },
  ],
  Legal: [
    { label: "Privacy Policy",    href: "/privacy" },
    { label: "Terms of Service",  href: "/terms" },
    { label: "Risk Disclaimer",   href: "/disclaimer" },
    { label: "Cookie Policy",     href: "/cookies" },
  ],
};

export default function Footer() {
  return (
    <footer className="border-t border-white/5 bg-[#0a0b0f]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-12">
          {/* Brand */}
          <div className="lg:col-span-2">
            <Link href="/" className="flex items-center gap-2.5 mb-4 group">
              <div
                className="w-8 h-8 rounded-lg flex items-center justify-center"
                style={{ background: "linear-gradient(135deg, #00ff88, #00cc6a)" }}
              >
                <Zap className="w-4 h-4 text-black" strokeWidth={2.5} />
              </div>
              <span className="text-base font-bold text-white">
                Coin<span style={{ color: "#00ff88" }}>astra</span>
              </span>
            </Link>
            <p className="text-sm text-white/35 leading-relaxed mb-6 max-w-xs">
              AI-powered crypto intelligence for traders who want to think clearer,
              manage risk better, and understand markets deeper.
            </p>
            <div className="flex items-center gap-3">
              {[
                { icon: Twitter, href: "#", label: "Twitter" },
                { icon: Github, href: "#", label: "GitHub" },
                { icon: MessageCircle, href: "#", label: "Discord" },
              ].map(({ icon: Icon, href, label }) => (
                <a
                  key={label}
                  href={href}
                  aria-label={label}
                  className="w-8 h-8 rounded-lg flex items-center justify-center text-white/30 hover:text-white hover:bg-white/5 transition-all"
                >
                  <Icon className="w-4 h-4" />
                </a>
              ))}
            </div>
          </div>

          {/* Links */}
          {Object.entries(footerLinks).map(([category, links]) => (
            <div key={category}>
              <h4 className="text-xs font-semibold text-white/40 uppercase tracking-wider mb-4">
                {category}
              </h4>
              <ul className="space-y-3">
                {links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className="text-sm text-white/40 hover:text-white/70 transition-colors"
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="border-t border-white/5 mt-12 pt-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-xs text-white/20">
            © 2026 Coinastra. All rights reserved.
          </p>
          <p className="text-xs text-white/15 text-center sm:text-right max-w-xs">
            Not financial advice. Crypto trading involves significant risk. Past patterns
            do not guarantee future results.
          </p>
        </div>
      </div>
    </footer>
  );
}
