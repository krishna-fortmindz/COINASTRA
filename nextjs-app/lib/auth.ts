const ACCESS_KEY = "coinastra_access";
const REFRESH_KEY = "coinastra_refresh";

export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(ACCESS_KEY);
}

export function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(REFRESH_KEY);
}

export function setTokens(access: string, refresh: string) {
  localStorage.setItem(ACCESS_KEY, access);
  localStorage.setItem(REFRESH_KEY, refresh);
}

export function clearTokens() {
  localStorage.removeItem(ACCESS_KEY);
  localStorage.removeItem(REFRESH_KEY);
}

export function isLoggedIn(): boolean {
  return !!getAccessToken();
}

async function refreshAccessToken(): Promise<string | null> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return null;
  try {
    const res = await fetch("/api/auth/refresh", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
    });
    if (!res.ok) { clearTokens(); return null; }
    const data = await res.json();
    const newAccess = data?.data?.accessToken ?? data?.accessToken;
    const newRefresh = data?.data?.refreshToken ?? data?.refreshToken ?? refreshToken;
    if (newAccess) { setTokens(newAccess, newRefresh); return newAccess; }
    return null;
  } catch {
    return null;
  }
}

export async function authFetch(url: string, options: RequestInit = {}): Promise<Response> {
  let token = getAccessToken();
  const doRequest = (t: string | null) =>
    fetch(url, {
      ...options,
      headers: {
        "Content-Type": "application/json",
        ...(t ? { Authorization: `Bearer ${t}` } : {}),
        ...(options.headers ?? {}),
      },
    });

  let res = await doRequest(token);
  if (res.status === 401) {
    token = await refreshAccessToken();
    if (token) res = await doRequest(token);
  }
  return res;
}
