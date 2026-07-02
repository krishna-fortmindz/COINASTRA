import type { MetadataRoute } from "next";

const PRIVATE = ["/auth/", "/app/", "/api/"];

export default function robots(): MetadataRoute.Robots {
  const baseUrl = process.env.NEXT_PUBLIC_APP_URL || "https://coinastra.site";
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        disallow: ["/auth/", "/app/", "/api/", "/_next/"],
      },
      // OpenAI — ChatGPT, search, and browsing
      { userAgent: "GPTBot", allow: "/", disallow: PRIVATE },
      { userAgent: "ChatGPT-User", allow: "/", disallow: PRIVATE },
      { userAgent: "OAI-SearchBot", allow: "/", disallow: PRIVATE },
      // Anthropic Claude
      { userAgent: "ClaudeBot", allow: "/", disallow: PRIVATE },
      { userAgent: "anthropic-ai", allow: "/", disallow: PRIVATE },
      // Google Gemini / AI Overviews
      { userAgent: "Google-Extended", allow: "/", disallow: PRIVATE },
      { userAgent: "Gemini-Bot", allow: "/", disallow: PRIVATE },
      // Perplexity AI
      { userAgent: "PerplexityBot", allow: "/", disallow: PRIVATE },
      // Meta AI
      { userAgent: "Meta-ExternalAgent", allow: "/", disallow: PRIVATE },
      { userAgent: "FacebookBot", allow: "/", disallow: PRIVATE },
      // Amazon Alexa AI
      { userAgent: "Amazonbot", allow: "/", disallow: PRIVATE },
      // Apple AI (Siri, Spotlight)
      { userAgent: "Applebot-Extended", allow: "/", disallow: PRIVATE },
      // You.com AI search
      { userAgent: "YouBot", allow: "/", disallow: PRIVATE },
      // DuckDuckGo AI
      { userAgent: "DuckAssistBot", allow: "/", disallow: PRIVATE },
      // Cohere AI
      { userAgent: "cohere-ai", allow: "/", disallow: PRIVATE },
      // Common Crawl — feeds training data for many AI models
      { userAgent: "CCBot", allow: ["/", "/blog/"], disallow: PRIVATE },
    ],
    sitemap: `${baseUrl}/sitemap.xml`,
    host: baseUrl,
  };
}