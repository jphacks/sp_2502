import type { DBLike } from "@/server/db";
import { users } from "@/server/db/schema/users";
import { type AppError, Errors } from "@/server/types/errors";
import { type AsyncResult, Err, Ok } from "@/server/types/result";

type UpsertUserInput = {
  id: string;
  email?: string | null;
  name?: string | null;
  image?: string | null;
};

export const upsertUser = async (
  dbLike: DBLike,
  input: UpsertUserInput,
): AsyncResult<typeof users.$inferSelect, AppError> => {
  try {
    const [user] = await dbLike
      .insert(users)
      .values({
        id: input.id,
        email: input.email,
        name: input.name,
        image: input.image,
        emailVerified: null,
      })
      .onConflictDoUpdate({
        target: users.id,
        set: {
          email: input.email,
          name: input.name,
          image: input.image,
          // emailVerifiedは更新しない（既存の値を保持）
        },
      })
      .returning();

    if (!user) {
      return Err(
        Errors.infraDb(
          "USER_UPSERT_FAILED",
          new Error("No user returned from upsert"),
        ),
      );
    }

    return Ok(user);
  } catch (error) {
    console.error("Database error in upsertUser:", {
      input,
      error,
      errorMessage: error instanceof Error ? error.message : String(error),
      errorStack: error instanceof Error ? error.stack : undefined,
    });
    return Err(Errors.infraDb("USER_UPSERT_FAILED", error));
  }
};
