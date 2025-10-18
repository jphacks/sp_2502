import { relations } from "drizzle-orm";

import { users } from "./users";

export const usersRelations = relations(users, () => ({
  // Add relations here as needed
}));
