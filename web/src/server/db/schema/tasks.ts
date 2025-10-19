import { pgEnum } from "drizzle-orm/pg-core";

import { createTable } from "./_table";
import { projects } from "./projects";
import { users } from "./users";

export const taskStatusEnum = pgEnum("task_status", [
  "unprocessed",
  "active",
  "completed",
  "waiting",
]);

export const tasks = createTable("task", d => ({
  id: d
    .varchar({ length: 255 })
    .notNull()
    .primaryKey()
    .$defaultFn(() => crypto.randomUUID()),
  userId: d
    .varchar({ length: 255 })
    .notNull()
    .references(() => users.id),
  projectId: d
    .varchar({ length: 255 })
    .notNull()
    .references(() => projects.id),
  name: d.varchar({ length: 255 }).notNull(),
  date: d.timestamp({ withTimezone: true }),
  status: taskStatusEnum().notNull().default("unprocessed"),
  priority: d.varchar({ length: 50 }),
  parentId: d.varchar({ length: 255 }),
  createdAt: d.timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: d.timestamp({ withTimezone: true }).$onUpdate(() => new Date()),
}));

export type InsertTask = typeof tasks.$inferInsert;
export type SelectTask = typeof tasks.$inferSelect;
