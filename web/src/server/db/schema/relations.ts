import { relations } from "drizzle-orm";

import { projects } from "./projects";
import { taskChildren } from "./task_children";
import { tasks } from "./tasks";
import { users } from "./users";

export const usersRelations = relations(users, ({ many }) => ({
  projects: many(projects),
  tasks: many(tasks),
}));

export const projectsRelations = relations(projects, ({ one, many }) => ({
  user: one(users, {
    fields: [projects.userId],
    references: [users.id],
  }),
  rootTask: one(tasks, {
    fields: [projects.rootTaskId],
    references: [tasks.id],
  }),
  tasks: many(tasks),
}));

export const tasksRelations = relations(tasks, ({ one, many }) => ({
  user: one(users, {
    fields: [tasks.userId],
    references: [users.id],
  }),
  project: one(projects, {
    fields: [tasks.projectId],
    references: [projects.id],
  }),
  parent: one(tasks, {
    fields: [tasks.parentId],
    references: [tasks.id],
    relationName: "parentTask",
  }),
  children: many(tasks, {
    relationName: "parentTask",
  }),
  taskChildrenAsParent: many(taskChildren, {
    relationName: "taskChildrenParent",
  }),
  taskChildrenAsChild: many(taskChildren, {
    relationName: "taskChildrenChild",
  }),
}));

export const taskChildrenRelations = relations(taskChildren, ({ one }) => ({
  task: one(tasks, {
    fields: [taskChildren.taskId],
    references: [tasks.id],
    relationName: "taskChildrenParent",
  }),
  child: one(tasks, {
    fields: [taskChildren.childId],
    references: [tasks.id],
    relationName: "taskChildrenChild",
  }),
}));
