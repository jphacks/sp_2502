import { DrizzleAdapter } from "@auth/drizzle-adapter";
import DiscordProvider from "next-auth/providers/discord";

import { db } from "@/server/db";
import { accounts } from "@/server/db/schema/accounts";
import { sessions } from "@/server/db/schema/sessions";
import { users } from "@/server/db/schema/users";

import type { DefaultSession, NextAuthConfig } from "next-auth";

/**
 * Session.user.idを型安全に使えるようにする宣言
 *
 * @see https://next-auth.js.org/getting-started/typescript#module-augmentation
 */
declare module "next-auth" {
  interface Session extends DefaultSession {
    user: {
      id: string;
    } & DefaultSession["user"];
  }
}

/**
 * NextAuthの設定
 *
 * @see https://next-auth.js.org/configuration/options
 */
export const authConfig = {
  session: { strategy: "database" },
  // プロバイダー追加するならここ
  providers: [DiscordProvider],
  adapter: DrizzleAdapter(db, {
    usersTable: users,
    accountsTable: accounts,
    sessionsTable: sessions,
  }),
  callbacks: {
    session: ({ session, user }) => ({
      ...session,
      user: {
        ...session.user,
        id: user.id,
      },
    }),
  },
} satisfies NextAuthConfig;
