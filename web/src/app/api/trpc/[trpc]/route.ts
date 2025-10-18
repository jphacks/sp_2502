import { fetchRequestHandler } from "@trpc/server/adapters/fetch";

import { env } from "@/env";
import { appRouter } from "@/server/api/root";
import { createTRPCContext } from "@/server/api/trpc";

import type { NextRequest } from "next/server";

const ALLOWED_ORIGINS = [
  env.AUTH0_BASE_URL, // 例: https://app.example.com
  "http://localhost:3304",
].filter(Boolean);

const pickOrigin = (req: NextRequest) => {
  const origin = req.headers.get("origin");
  return origin && ALLOWED_ORIGINS.includes(origin) ? origin : null;
};

const buildCorsHeaders = (req: NextRequest) => {
  const origin = pickOrigin(req);
  const reqHeaders =
    req.headers.get("access-control-request-headers") ??
    "authorization,content-type";
  const h = new Headers();
  if (origin) {
    h.set("Access-Control-Allow-Origin", origin);
    h.set("Access-Control-Allow-Credentials", "true");
  }
  h.set("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  h.set("Access-Control-Allow-Headers", reqHeaders);
  h.set("Access-Control-Max-Age", "86400");
  h.append("Vary", "Origin");
  h.append("Vary", "Access-Control-Request-Headers");
  return h;
};

const createContext = async (req: NextRequest) =>
  createTRPCContext({ headers: req.headers });

const handler = async (req: NextRequest) => {
  // Preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: buildCorsHeaders(req) });
  }

  // tRPC 本体
  const trpcResp = await fetchRequestHandler({
    endpoint: "/api/trpc",
    req,
    router: appRouter,
    createContext: () => createContext(req),
    onError:
      env.NODE_ENV === "development"
        ? ({ path, error }) =>
            console.error(`❌ tRPC ${path ?? "<no-path>"}: ${error.message}`)
        : undefined,
  });

  // 返却ヘッダーに CORS を付与（Set-Cookie を壊さない）
  const res = new Response(trpcResp.body, {
    status: trpcResp.status,
    headers: trpcResp.headers,
  });
  buildCorsHeaders(req).forEach((v, k) => res.headers.set(k, v));
  return res;
};

export { handler as GET, handler as POST, handler as OPTIONS };
