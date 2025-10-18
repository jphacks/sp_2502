import { uniqueIndex } from "drizzle-orm/pg-core";

import { createTable } from "./_table";

export const users = createTable(
  "user",
  d => ({
    id: d
      .varchar({ length: 255 })
      .notNull()
      .primaryKey()
      .$defaultFn(() => crypto.randomUUID()),
    name: d.varchar({ length: 255 }),
    email: d.varchar({ length: 255 }),
    emailVerified: d.timestamp({ mode: "date", withTimezone: true }),
    image: d.varchar({ length: 255 }),
  }),
  t => [uniqueIndex("user_email_unique").on(t.email)],
);

export type InsertUser = typeof users.$inferInsert;
export type SelectUser = typeof users.$inferSelect;
