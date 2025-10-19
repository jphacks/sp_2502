// app/auth/logout/route.ts
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  const domain = process.env.AUTH0_DOMAIN!; // 例: dev-xxxx.us.auth0.com
  const clientId = process.env.AUTH0_CLIENT_ID!;
  const returnTo = process.env.NEXT_PUBLIC_BASE_URL!; // 例: https://sp-2502.vercel.app/

  const url = new URL(`https://${domain}/v2/logout`);
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("returnTo", returnTo);

  return NextResponse.redirect(url.toString(), 302);
}
