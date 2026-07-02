import type { Metadata } from "next";
import Link from "next/link";
import { Zap, ArrowLeft } from "lucide-react";

export const metadata: Metadata = {
  title: "Page Not Found",
  description: "The page you're looking for doesn't exist. Head back to Coinastra and keep trading smarter.",
  robots: { index: false, follow: true },
};

export default function NotFound() {
  return (
    <div className="min-h-screen bg-[#0a0b0f] flex flex-col items-center justify-center px-4">
      <div className="fixed inset-0 grid-bg opacity-30 pointer-events-none" />
      <div className="relative text-center">
        <div
          className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-6"
          style={{ background: "linear-gradient(135deg, #00ff88, #00cc6a)" }}
        >
          <Zap className="w-8 h-8 text-black" />
        </div>
        <h1 className="text-6xl font-black text-white mb-3">404</h1>
        <p className="text-white/40 mb-8">This page has left the chat.</p>
        <Link href="/" className="btn-primary inline-flex gap-2">
          <ArrowLeft className="w-4 h-4" />
          Back to home
        </Link>
      </div>
    </div>
  );
}
