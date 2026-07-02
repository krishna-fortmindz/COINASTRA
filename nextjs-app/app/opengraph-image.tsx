import { ImageResponse } from "next/og";

export const runtime = "edge";
export const alt = "Coinastra — AI-Powered Crypto Trading Intelligence";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          background: "#0a0b0f",
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: "Inter, system-ui, sans-serif",
          position: "relative",
          overflow: "hidden",
        }}
      >
        {/* Grid background */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            backgroundImage:
              "linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px)",
            backgroundSize: "48px 48px",
          }}
        />
        {/* Green radial glow */}
        <div
          style={{
            position: "absolute",
            top: "50%",
            left: "50%",
            transform: "translate(-50%, -50%)",
            width: 800,
            height: 500,
            background:
              "radial-gradient(ellipse, rgba(0,255,136,0.10) 0%, transparent 70%)",
          }}
        />

        {/* Logo + Brand */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 20,
            marginBottom: 36,
          }}
        >
          <div
            style={{
              width: 64,
              height: 64,
              borderRadius: 18,
              background: "linear-gradient(135deg, #00ff88, #00cc6a)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 32,
              fontWeight: 900,
              color: "#000",
            }}
          >
            ⚡
          </div>
          <span
            style={{
              fontSize: 44,
              fontWeight: 900,
              color: "#fff",
              letterSpacing: "-1px",
            }}
          >
            Coin
            <span style={{ color: "#00ff88" }}>astra</span>
          </span>
        </div>

        {/* Headline */}
        <div
          style={{
            fontSize: 52,
            fontWeight: 900,
            color: "#fff",
            textAlign: "center",
            lineHeight: 1.1,
            maxWidth: 960,
            marginBottom: 24,
            letterSpacing: "-1.5px",
          }}
        >
          AI-Powered Crypto Trading
          <br />
          <span style={{ color: "#00ff88" }}>Intelligence</span>
        </div>

        {/* Subtext */}
        <div
          style={{
            fontSize: 22,
            color: "rgba(255,255,255,0.45)",
            textAlign: "center",
            maxWidth: 720,
            lineHeight: 1.5,
          }}
        >
          Real-time AI analysis · Whale alerts · Sentiment signals · Risk management
        </div>

        {/* Bottom pill */}
        <div
          style={{
            position: "absolute",
            bottom: 44,
            display: "flex",
            alignItems: "center",
            gap: 10,
            background: "rgba(0,255,136,0.08)",
            border: "1px solid rgba(0,255,136,0.2)",
            borderRadius: 100,
            padding: "10px 24px",
            fontSize: 18,
            color: "#00ff88",
            fontWeight: 600,
          }}
        >
          ● Live Market Data · 12,000+ Active Traders
        </div>
      </div>
    ),
    size
  );
}