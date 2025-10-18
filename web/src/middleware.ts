import { auth0 } from "@/lib/auth0";

import type { NextRequest } from "next/server";

export const middleware = async (request: NextRequest) => {
  return await auth0.middleware(request);
};

export const config = {
  matcher: ["/auth/:path*"],
};
