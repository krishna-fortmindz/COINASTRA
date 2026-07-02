/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    optimizePackageImports: ["lucide-react", "framer-motion"],
    serverComponentsExternalPackages: ["socket.io-client", "engine.io-client"],
  },

  images: {
    remotePatterns: [
      { protocol: "https", hostname: "assets.coingecko.com" },
      { protocol: "https", hostname: "cryptologos.cc" },
      { protocol: "https", hostname: "coin-images.coingecko.com" },
    ],
    formats: ["image/avif", "image/webp"],
  },

  async rewrites() {
    if (process.env.NODE_ENV !== "production") {
      return [
        { source: "/app/:path*", destination: "http://localhost:5001/:path*" },
        { source: "/dashboard/:path*", destination: "http://localhost:5001/dashboard/:path*" },
        { source: "/analysis/:path*", destination: "http://localhost:5001/analysis/:path*" },
        { source: "/charts/:path*", destination: "http://localhost:5001/charts/:path*" },
        { source: "/chat/:path*", destination: "http://localhost:5001/chat/:path*" },
      ];
    }

    return [
      { source: "/app", destination: "/app/index.html" },
      { source: "/app/", destination: "/app/index.html" },
      { source: "/app/:path*", destination: "/app/index.html" },
    ];
  },

  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "X-DNS-Prefetch-Control", value: "on" },
          {
            key: "Strict-Transport-Security",
            value: "max-age=63072000; includeSubDomains; preload",
          },
          {
            key: "Permissions-Policy",
            value: "camera=(), microphone=(), geolocation=(), payment=()",
          },
        ],
      },
      // Prevent indexing of auth and API routes
      {
        source: "/auth/(.*)",
        headers: [{ key: "X-Robots-Tag", value: "noindex, nofollow" }],
      },
      {
        source: "/api/(.*)",
        headers: [{ key: "X-Robots-Tag", value: "noindex, nofollow" }],
      },
      // Long-lived cache for static Flutter assets
      {
        source: "/app/canvaskit/(.*)",
        headers: [
          { key: "Cache-Control", value: "public, max-age=31536000, immutable" },
        ],
      },
      {
        source: "/app/assets/(.*)",
        headers: [
          { key: "Cache-Control", value: "public, max-age=31536000, immutable" },
        ],
      },
    ];
  },
};

export default nextConfig;
