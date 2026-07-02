import type { Metadata, Viewport } from "next";
import Script from "next/script";
import { Analytics } from "@vercel/analytics/next";
import "./globals.css";

const APP_URL = process.env.NEXT_PUBLIC_APP_URL || "https://coinastra.site";
const BRAND = "Coinastra";
const TAGLINE = "AI-Powered Crypto Trading Intelligence";
const DESCRIPTION =
  "Real-time AI market analysis, whale alerts, sentiment signals, and risk management for serious crypto traders. The AI copilot that makes you a smarter trader.";

export const viewport: Viewport = {
  themeColor: "#00ff88",
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
};

export const metadata: Metadata = {
  metadataBase: new URL(APP_URL),
  title: {
    default: `${BRAND} — ${TAGLINE}`,
    template: `%s | ${BRAND}`,
  },
  description: DESCRIPTION,
  keywords: [
    "crypto trading AI",
    "AI crypto analysis",
    "bitcoin AI analysis",
    "crypto intelligence platform",
    "trading copilot",
    "market sentiment analysis",
    "crypto risk management",
    "AI trading assistant",
    "crypto pattern recognition",
    "whale alert crypto",
    "fear greed index",
    "market memory engine",
    "crypto trade journal",
    "funding rate alerts",
    "new crypto listings",
    "Binance trading tools",
    "crypto portfolio management",
    "on-chain sentiment analysis",
    "coinastra",
  ],
  authors: [{ name: BRAND, url: APP_URL }],
  creator: BRAND,
  publisher: BRAND,
  category: "Finance",
  applicationName: BRAND,
  referrer: "origin-when-cross-origin",
  alternates: {
    canonical: "/",
    types: {
      "application/rss+xml": `${APP_URL}/feed.xml`,
    },
  },
  openGraph: {
    type: "website",
    locale: "en_US",
    url: APP_URL,
    siteName: BRAND,
    title: `${BRAND} — ${TAGLINE}`,
    description: DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    site: "@coinastra",
    creator: "@coinastra",
    title: `${BRAND} — ${TAGLINE}`,
    description: DESCRIPTION,
  },
  robots: {
    index: true,
    follow: true,
    nocache: false,
    googleBot: {
      index: true,
      follow: true,
      noimageindex: false,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  manifest: "/site.webmanifest",
  icons: {
    icon: [
      { url: "/icon.svg", type: "image/svg+xml" },
      { url: "/favicon.ico", sizes: "any" },
    ],
    shortcut: "/favicon.ico",
    apple: [{ url: "/apple-touch-icon.png", sizes: "180x180", type: "image/png" }],
  },
};

const organizationSchema = {
  "@context": "https://schema.org",
  "@type": "Organization",
  "@id": `${APP_URL}/#organization`,
  name: BRAND,
  url: APP_URL,
  logo: {
    "@type": "ImageObject",
    "@id": `${APP_URL}/#logo`,
    url: `${APP_URL}/opengraph-image`,
    width: 1200,
    height: 630,
    caption: BRAND,
  },
  description: DESCRIPTION,
  foundingDate: "2024",
  sameAs: [
    "https://twitter.com/coinastra",
    "https://github.com/coinastra",
    "https://discord.gg/coinastra",
    "https://status.coinastra.site",
  ],
  contactPoint: {
    "@type": "ContactPoint",
    contactType: "customer support",
    url: `${APP_URL}/contact`,
    availableLanguage: "English",
  },
};

const websiteSchema = {
  "@context": "https://schema.org",
  "@type": "WebSite",
  "@id": `${APP_URL}/#website`,
  url: APP_URL,
  name: BRAND,
  description: DESCRIPTION,
  publisher: { "@id": `${APP_URL}/#organization` },
  inLanguage: "en-US",
  potentialAction: {
    "@type": "SearchAction",
    target: {
      "@type": "EntryPoint",
      urlTemplate: `${APP_URL}/blog?q={search_term_string}`,
    },
    "query-input": "required name=search_term_string",
  },
};

// Speakable schema — tells AI assistants and voice search which
// page sections contain the most answer-worthy content.
const speakableSchema = {
  "@context": "https://schema.org",
  "@type": "WebPage",
  "@id": `${APP_URL}/#webpage`,
  url: APP_URL,
  name: `${BRAND} — ${TAGLINE}`,
  isPartOf: { "@id": `${APP_URL}/#website` },
  about: { "@id": `${APP_URL}/#organization` },
  speakable: {
    "@type": "SpeakableSpecification",
    cssSelector: ["h1", "h2", "[data-speakable]"],
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;600&display=swap"
          rel="stylesheet"
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify([organizationSchema, websiteSchema, speakableSchema]),
          }}
        />
      </head>
      <body className="bg-bg-primary text-white antialiased overflow-x-hidden">
        {children}
        <Analytics />
        <Script
          src="https://www.googletagmanager.com/gtag/js?id=G-LV1C2P4FW2"
          strategy="afterInteractive"
        />
        <Script id="google-analytics" strategy="afterInteractive">
          {`
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', 'G-LV1C2P4FW2');
          `}
        </Script>
      </body>
    </html>
  );
}