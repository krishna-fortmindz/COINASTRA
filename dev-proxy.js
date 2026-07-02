/**
 * Local dev proxy — mirrors the production nginx config.
 * Runs on :8080 and routes:
 *   /dashboard, /analysis, /charts, /memory, /sentiment,
 *   /listings, /risk, /journal, /chat, /alerts, /profile
 *   + all Flutter static assets  →  Flutter (:5001)
 *
 *   /socket.io, /api/v1/, /api/sentiment/social, /api/sentiment/coins,
 *   /api/sentiment/onchain, /api/ai/analysis, /api/ai/listings,
 *   /api/journal, /api/risk   →  Backend (:5000)
 *
 *   everything else            →  Next.js (:3000)
 */

const http = require("http");
const httpProxy = require("http-proxy");

const NEXTJS_URL = "http://localhost:3000";
const FLUTTER_URL = "http://localhost:5001";
const BACKEND_URL = "http://10.255.251.45:5000";
const PROXY_PORT = 8080;

// Routes that belong to the Flutter dashboard
const FLUTTER_APP_ROUTES = [
  "/app",
  "/dashboard",
  "/analysis",
  "/charts",
  "/memory",
  "/sentiment",
  "/listings",
  "/risk",
  "/journal",
  "/chat",
  "/alerts",
  "/profile",
  "/trade-now",
  "/onchain",
  "/orderbook",
  "/token-unlocks",
  "/portfolio",
  "/predictions",
];

// Paths that must always go straight to the backend server.
// Order matters — more specific prefixes first.
const BACKEND_API_PREFIXES = [
  "/socket.io",       // Socket.IO (HTTP polling + WS upgrade)
  "/api/v1/",         // All main backend REST APIs
  "/api/sentiment/social",
  "/api/sentiment/coins",
  "/api/sentiment/onchain",
  "/api/ai/analysis",
  "/api/ai/listings",
  "/api/journal",
  "/api/risk",
];

// Known Flutter static asset patterns (fallback for direct asset requests)
const FLUTTER_ASSET_PATTERNS = [
  /^\/main\.dart\.js/,
  /^\/flutter\.js/,
  /^\/flutter_bootstrap\.js/,
  /^\/flutter_service_worker\.js/,
  /^\/canvaskit\//,
  /^\/assets\//,
  /^\/icons\//,
  /^\/packages\//,           // DDC package modules (intl, timeago, etc.)
  /^\/version\.json/,
  /^\/stack_trace_mapper\.js/,
  /^\/ddc_module_loader\.js/,
  /^\/dart_sdk\.js/,
  /^\/[^/]+\.ddc\.js/,
  /^\/[^/]+\.dart\.lib\.js/,
  /^\/[^/]+\.bootstrap\.js/,
  /^\/on_load_end_bootstrap\.js/,
  /^\/favicon\.png/,
  /^\/manifest\.json/,
  /^\/site\.webmanifest/,
];

function getPathname(urlOrPathname) {
  try {
    return new URL(urlOrPathname, "http://localhost").pathname;
  } catch (_) {
    return urlOrPathname.split("?")[0];
  }
}

function isBackendApiRequest(url) {
  const pathname = getPathname(url);
  return BACKEND_API_PREFIXES.some((p) => pathname.startsWith(p));
}

function isFlutterRoute(urlOrPathname) {
  const pathname = getPathname(urlOrPathname);
  return FLUTTER_APP_ROUTES.some(
    (r) => pathname === r || pathname.startsWith(r + "/")
  );
}

function isFlutterRequest(url, referer) {
  if (isFlutterRoute(url)) return true;
  if (FLUTTER_ASSET_PATTERNS.some((re) => re.test(url))) return true;
  if (referer) {
    try {
      const refPath = new URL(referer).pathname;
      if (isFlutterRoute(refPath)) return true;
    } catch (_) { }
  }
  return false;
}

const proxy = httpProxy.createProxyServer({ ws: true });

proxy.on("error", (err, req, res) => {
  console.error(`[proxy error] ${req.url} →`, err.message);
  if (!res) return;
  // WebSocket upgrade errors give us a net.Socket, not an http.ServerResponse
  if (typeof res.writeHead === "function") {
    if (!res.headersSent) {
      res.writeHead(502, { "Content-Type": "text/plain" });
      res.end(`Proxy error: ${err.message}`);
    }
  } else if (typeof res.destroy === "function") {
    res.destroy();
  }
});

const server = http.createServer((req, res) => {
  // 1. Backend API + Socket.IO — checked first to avoid conflicts with Next.js /api routes
  if (isBackendApiRequest(req.url)) {
    proxy.web(req, res, { target: BACKEND_URL });
    return;
  }

  // 2. Flutter dashboard routes + assets
  const referer = req.headers["referer"] || req.headers["referrer"];
  if (isFlutterRequest(req.url, referer)) {
    if (isFlutterRoute(req.url)) {
      const search = new URL(req.url, "http://localhost").search;
      req.url = "/" + search;
    }
    proxy.web(req, res, { target: FLUTTER_URL });
    return;
  }

  // 3. Everything else → Next.js
  proxy.web(req, res, { target: NEXTJS_URL });
});

// WebSocket upgrades: Socket.IO → backend, others → Flutter/Next.js
server.on("upgrade", (req, socket, head) => {
  if (isBackendApiRequest(req.url)) {
    proxy.ws(req, socket, head, { target: BACKEND_URL });
    return;
  }
  const referer = req.headers["referer"] || req.headers["referrer"];
  const target = isFlutterRequest(req.url, referer) ? FLUTTER_URL : NEXTJS_URL;
  proxy.ws(req, socket, head, { target });
});

server.listen(PROXY_PORT, () => {
  console.log("\n┌─────────────────────────────────────────────┐");
  console.log("│   AI Trading Copilot — Dev Proxy            │");
  console.log("├─────────────────────────────────────────────┤");
  console.log(`│   Proxy   →  http://localhost:${PROXY_PORT}          │`);
  console.log(`│   Next.js →  http://localhost:3000           │`);
  console.log(`│   Flutter →  http://localhost:5001           │`);
  console.log(`│   Backend →  http://10.255.251.45:5000        │`);
  console.log("└─────────────────────────────────────────────┘\n");
  console.log("  Open  http://localhost:8080  in your browser.\n");
});
