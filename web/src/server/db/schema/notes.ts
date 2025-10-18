import { createTable } from "./_table";
import { users } from "./users";

export const notes = createTable("note", d => ({
  id: d
    .varchar({ length: 255 })
    .notNull()
    .primaryKey()
    .$defaultFn(() => crypto.randomUUID()),
  userId: d
    .varchar({ length: 255 })
    .notNull()
    .references(() => users.id),
  title: d.varchar({ length: 255 }).notNull().default(""),
  content: d.text().notNull().default(""),
  createdAt: d.timestamp({ withTimezone: true }).default(new Date()).notNull(),
  updatedAt: d.timestamp({ withTimezone: true }).$onUpdate(() => new Date()),
}));

export type InsertNote = typeof notes.$inferInsert;
export type SelectNote = typeof notes.$inferSelect;
