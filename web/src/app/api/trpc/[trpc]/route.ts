// app/api/trpc/[trpc]/route.ts
import { fetchRequestHandler } from "@trpc/server/adapters/fetch";
import { NextResponse } from "next/server";

import { env } from "@/env";
import { appRouter } from "@/server/api/root";
import { createTRPCContext } from "@/server/api/trpc";

import type { NextRequest } from "next/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const createContext = async (req: NextRequest) => {
  return createTRPCContext({ headers: req.headers });
};

const getAllowedOrigin = (requestOrigin: string | null): string => {
  // 開発環境では全てのオリジンを許可
  if (env.NODE_ENV === "development") {
    return requestOrigin ?? "*";
  }

  // 本番環境では設定されたベースURLのみ許可
  const allowedOrigins = [env.AUTH0_BASE_URL];

  if (requestOrigin && allowedOrigins.includes(requestOrigin)) {
    return requestOrigin;
  }

  // デフォルトは設定されたベースURL
  return env.AUTH0_BASE_URL;
};

const setCorsHeaders = (res: Response, origin: string): Response => {
  const headers = new Headers(res.headers);
  headers.set("Access-Control-Allow-Origin", origin);
  headers.set("Access-Control-Allow-Credentials", "true");
  headers.set(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, DELETE, OPTIONS",
  );
  headers.set(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization, x-trpc-source",
  );
  headers.set("Access-Control-Max-Age", "86400");

  return new Response(res.body, {
    status: res.status,
    statusText: res.statusText,
    headers,
  });
};

const handler = async (req: NextRequest) => {
  const origin = req.headers.get("origin");
  const allowedOrigin = getAllowedOrigin(origin);

  // Handle preflight requests
  if (req.method === "OPTIONS") {
    return new NextResponse(null, {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": allowedOrigin,
        "Access-Control-Allow-Credentials": "true",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type, Authorization, x-trpc-source",
        "Access-Control-Max-Age": "86400",
      },
    });
  }

  const response = await fetchRequestHandler({
    endpoint: "/api/trpc",
    req,
    router: appRouter,
    createContext: () => createContext(req),
  });

  return setCorsHeaders(response, allowedOrigin);
};

export { handler as GET, handler as POST, handler as OPTIONS };
