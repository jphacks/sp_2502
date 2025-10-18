import { auth0 } from "@/lib/auth0";

export const getSession = async () => {
  const session = await auth0.getSession();

  // Debug logging for Vercel
  if (process.env.NODE_ENV === "production") {
    console.log("[getSession] Session retrieved:", {
      hasSession: !!session,
      hasUser: !!session?.user,
      userId: session?.user?.sub,
      userEmail: session?.user?.email,
    });
  }

  return session;
};
