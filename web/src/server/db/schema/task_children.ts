import { createTable } from "./_table";
import { tasks } from "./tasks";

export const taskChildren = createTable("task_children", d => ({
  id: d
    .varchar({ length: 255 })
    .notNull()
    .primaryKey()
    .$defaultFn(() => crypto.randomUUID()),
  taskId: d
    .varchar({ length: 255 })
    .notNull()
    .references(() => tasks.id),
  childId: d
    .varchar({ length: 255 })
    .notNull()
    .references(() => tasks.id),
  createdAt: d.timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: d.timestamp({ withTimezone: true }).$onUpdate(() => new Date()),
}));

export type InsertTaskChildren = typeof taskChildren.$inferInsert;
export type SelectTaskChildren = typeof taskChildren.$inferSelect;
