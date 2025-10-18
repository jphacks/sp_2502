import type { DBLike } from "@/server/db";

export type BaseDeps = { db: DBLike };
export type PublicDeps = BaseDeps & { authUserId: null };
export type AuthDeps = BaseDeps & { authUserId: string };
export type Deps = PublicDeps | AuthDeps;

export const createPublicDeps = (db: DBLike): PublicDeps => ({
  db,
  authUserId: null,
});
export const createAuthDeps = (db: DBLike, userId: string): AuthDeps => ({
  db,
  authUserId: userId,
});
