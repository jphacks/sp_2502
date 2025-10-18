import { env } from "@/env";

import type { Config } from "drizzle-kit";

export default {
  schema: "./src/server/db/schema",
  dialect: "postgresql",
  dbCredentials: {
    url: env.MIGRATE_PROD_DATABASE_URL,
  },
  tablesFilter: ["template_*"],
} satisfies Config;
