"use client";
import dynamic from "next/dynamic";
import Hero from "@/components/landing/Hero";
import { useMarketSocket } from "@/hooks/useMarketSocket";

const LiveMarket = dynamic(() => import("@/components/landing/LiveMarket"), { ssr: false });
const WhaleAlerts = dynamic(() => import("@/components/landing/WhaleAlerts"), { ssr: false });

export default function LandingPageClient() {
  const { tickers, whales, fundingRates, connected } = useMarketSocket();

  return (
    <>
      <Hero socketTickers={tickers} connected={connected} />
      <LiveMarket tickers={tickers} />
      <WhaleAlerts whales={whales} fundingRates={fundingRates} />
    </>
  );
}
