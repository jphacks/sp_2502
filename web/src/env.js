import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

const {
  NODE_ENV,
  AUTH0_SECRET,
  AUTH0_BASE_URL,
  AUTH0_ISSUER_BASE_URL,
  AUTH0_CLIENT_ID,
  AUTH0_CLIENT_SECRET,
  LOCAL_DATABASE_URL,
  PROD_DATABASE_URL,
  SKIP_ENV_VALIDATION,
  DB_RUNTIME,
  MIGRATE_PROD_DATABASE_URL,
} = process.env;

export const env = createEnv({
  /**
   * Specify your server-side environment variables schema here. This way you can ensure the app
   * isn't built with invalid env vars.
   */
  server: {
    AUTH0_SECRET: z.string(),
    AUTH0_BASE_URL: z.string().url(),
    AUTH0_ISSUER_BASE_URL: z.string().url(),
    AUTH0_CLIENT_ID: z.string(),
    AUTH0_CLIENT_SECRET: z.string(),
    DATABASE_URL: z.string().url(),
    NODE_ENV: z
      .enum(["development", "test", "production"])
      .default("development"),
    DB_RUNTIME: z.enum(["local", "neon"]).default("local"),
    MIGRATE_PROD_DATABASE_URL: z.string().url(),
  },

  /**
   * Specify your client-side environment variables schema here. This way you can ensure the app
   * isn't built with invalid env vars. To expose them to the client, prefix them with
   * `NEXT_PUBLIC_`.
   */
  client: {
    // NEXT_PUBLIC_CLIENTVAR: z.string(),
  },

  /**
   * You can't destruct `process.env` as a regular object in the Next.js edge runtimes (e.g.
   * middlewares) or client-side so we need to destruct manually.
   */
  runtimeEnv: {
    AUTH0_SECRET: AUTH0_SECRET,
    AUTH0_BASE_URL: AUTH0_BASE_URL,
    AUTH0_ISSUER_BASE_URL: AUTH0_ISSUER_BASE_URL,
    AUTH0_CLIENT_ID: AUTH0_CLIENT_ID,
    AUTH0_CLIENT_SECRET: AUTH0_CLIENT_SECRET,
    DATABASE_URL:
      DB_RUNTIME === "local" ? LOCAL_DATABASE_URL : PROD_DATABASE_URL,
    NODE_ENV: NODE_ENV,
    DB_RUNTIME: DB_RUNTIME,
    MIGRATE_PROD_DATABASE_URL:
      DB_RUNTIME === "local" ? LOCAL_DATABASE_URL : MIGRATE_PROD_DATABASE_URL,
  },
  /**
   * Run `build` or `dev` with `SKIP_ENV_VALIDATION` to skip env validation. This is especially
   * useful for Docker builds.
   */
  skipValidation: !!SKIP_ENV_VALIDATION,
  /**
   * Makes it so that empty strings are treated as undefined. `SOME_VAR: z.string()` and
   * `SOME_VAR=''` will throw an error.
   */
  emptyStringAsUndefined: true,
});
