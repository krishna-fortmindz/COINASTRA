"use client";
import { useEffect, useRef, useState } from "react";
import { getSocket } from "@/lib/socket";

export interface TickerData {
  symbol: string;
  price: number;
  open: number;
  high: number;
  low: number;
  volume: number;
  quoteVolume: number;
  changePct: number;
}

export interface WhaleAlert {
  symbol: string;
  amount: number;
  amountUsd: number;
  from: string;
  to: string;
  timestamp: number;
  toExchange: boolean;
}

export interface FundingRateItem {
  symbol: string;
  rate: number;
  formatted: string;
  positive: boolean;
}

const EXCHANGE_NAMES = new Set([
  "binance","coinbase","kraken","okx","bybit","huobi","kucoin","bitfinex","bitmex","gate",
]);

function parseName(v: unknown): string {
  if (v && typeof v === "object" && "name" in v) return String((v as any).name);
  return v ? String(v) : "Unknown";
}

export function useMarketSocket() {
  const [tickers, setTickers] = useState<Record<string, TickerData>>({});
  const [whales, setWhales] = useState<WhaleAlert[]>([]);
  const [fundingRates, setFundingRates] = useState<FundingRateItem[]>([]);
  const [connected, setConnected] = useState(false);
  const subscribedRef = useRef(false);

  useEffect(() => {
    const socket = getSocket();
    if (!socket.connected) socket.connect();

    const onConnect = () => {
      setConnected(true);
      if (!subscribedRef.current) {
        subscribedRef.current = true;
        socket.emit("dashboard:subscribe", {
          symbols: ["BTCUSDT","ETHUSDT","SOLUSDT","BNBUSDT","XRPUSDT","DOGEUSDT","AVAXUSDT","LINKUSDT","ARBUSDT","INJUSDT"],
          klineInterval: "1m",
          includeSnapshot: true,
          includeWhales: true,
          includeFunding: true,
          includeTrades: false,
        });
      }
    };

    const onDisconnect = () => {
      setConnected(false);
      subscribedRef.current = false;
    };

    const onMiniTicker = (data: unknown) => {
      if (!Array.isArray(data)) return;
      setTickers((prev) => {
        const next = { ...prev };
        (data as any[]).forEach((item) => {
          if (!item?.symbol) return;
          const close = Number(item.close) || 0;
          const open = Number(item.open) || 0;
          const changePct = open > 0 ? ((close - open) / open) * 100 : 0;
          next[item.symbol] = {
            symbol: item.symbol,
            price: close,
            open,
            high: Number(item.high) || 0,
            low: Number(item.low) || 0,
            volume: Number(item.baseVolume) || 0,
            quoteVolume: Number(item.quoteVolume) || 0,
            changePct,
          };
        });
        return next;
      });
    };

    const onSnapshot = (data: unknown) => {
      if (!data || typeof data !== "object") return;
      const d = data as Record<string, unknown>;

      if (Array.isArray(d.whaleAlerts)) {
        setWhales(
          (d.whaleAlerts as any[]).slice(0, 12).map((w) => ({
            symbol: String(w.symbol ?? "").toUpperCase(),
            amount: Number(w.amount) || 0,
            amountUsd: Number(w.amount_usd ?? w.amountUsd) || 0,
            from: parseName(w.from),
            to: parseName(w.to),
            timestamp: Number(w.timestamp) || Date.now(),
            toExchange: EXCHANGE_NAMES.has(parseName(w.to).toLowerCase()),
          }))
        );
      }

      if (Array.isArray(d.fundingRates)) {
        setFundingRates(
          (d.fundingRates as any[]).slice(0, 8).map((f) => {
            const rate = parseFloat(String(f.fundingRate ?? f.funding_rate ?? 0)) || 0;
            return {
              symbol: String(f.symbol ?? ""),
              rate,
              formatted: `${rate >= 0 ? "+" : ""}${(rate * 100).toFixed(4)}%`,
              positive: rate >= 0,
            };
          })
        );
      }
    };

    socket.on("connect", onConnect);
    socket.on("disconnect", onDisconnect);
    socket.on("market:miniTicker", onMiniTicker);
    socket.on("dashboard:snapshot", onSnapshot);
    if (socket.connected) onConnect();

    return () => {
      socket.off("connect", onConnect);
      socket.off("disconnect", onDisconnect);
      socket.off("market:miniTicker", onMiniTicker);
      socket.off("dashboard:snapshot", onSnapshot);
    };
  }, []);

  return { tickers, whales, fundingRates, connected };
}
