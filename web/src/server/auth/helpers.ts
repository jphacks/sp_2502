import { auth0 } from "@/lib/auth0";

export const getSession = async () => {
  return await auth0.getSession();
};
