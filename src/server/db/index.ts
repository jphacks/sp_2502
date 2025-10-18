import { Pool } from "@neondatabase/serverless";
import { drizzle as drizzleNeon } from "drizzle-orm/neon-serverless";
import { drizzle as drizzlePg } from "drizzle-orm/postgres-js";
import postgres from "postgres";

import { env } from "@/env";

import { accounts } from "./schema/accounts";
import { notes } from "./schema/notes";
import {
  accountsRelations,
  sessionsRelations,
  usersRelations,
} from "./schema/relations";
import { sessions } from "./schema/sessions";
import { users } from "./schema/users";

const schema = {
  accounts,
  notes,
  sessions,
  users,
  accountsRelations,
  sessionsRelations,
  usersRelations,
};

type DBPg = ReturnType<typeof drizzlePg>;
type DBNeon = ReturnType<typeof drizzleNeon>;
export type DB = DBPg | DBNeon;

const g = globalThis as unknown as {
  __db?: DB;
  __pool?: Pool;
  __pg?: postgres.Sql;
};

function createDb(): DB {
  if (env.DB_RUNTIME === "local") {
    const pg =
      g.__pg ?? postgres(env.DATABASE_URL, { max: 10, idle_timeout: 20 });
    if (env.NODE_ENV !== "production") g.__pg = pg;
    return drizzlePg(pg, { schema });
  }
  // Neon: WebSocket
  const pool = g.__pool ?? new Pool({ connectionString: env.DATABASE_URL });
  if (env.NODE_ENV !== "production") g.__pool = pool;
  return drizzleNeon({ client: pool, schema });
}

// HMR対策（Edgeではキャッシュしない想定）
export const db: DB = g.__db ?? createDb();
if (env.NODE_ENV !== "production") g.__db = db;

// 既存互換
export type DBLike =
  | typeof db
  | Parameters<Parameters<(typeof db)["transaction"]>[0]>[0];
