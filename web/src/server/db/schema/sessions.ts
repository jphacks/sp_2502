import { index } from "drizzle-orm/pg-core";

import { createTable } from "./_table";
import { users } from "./users";

export const sessions = createTable(
  "session",
  d => ({
    sessionToken: d.varchar({ length: 255 }).notNull().primaryKey(),
    userId: d
      .varchar({ length: 255 })
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    expires: d.timestamp({ mode: "date", withTimezone: true }).notNull(),
  }),
  t => [
    index("session_user_id_idx").on(t.userId),
    index("session_expires_idx").on(t.expires),
  ],
);

export type InsertSession = typeof sessions.$inferInsert;
export type SelectSession = typeof sessions.$inferSelect;
