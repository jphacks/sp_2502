import { protectedProcedure } from "@/server/api/trpc";
import { toTrpcError } from "@/server/types/errors";
import { createAuthDeps } from "@/server/utils/deps";

import { request, response } from "./contract";
import { execute } from "./service";

export const deleteNote = protectedProcedure
  .input(request)
  .output(response)
  .mutation(async ({ ctx, input }) => {
    const deps = createAuthDeps(ctx.db, ctx.session.user.id);

    const result = await execute(deps, input);
    if (!result.success) {
      throw toTrpcError(result.error);
    }
    return result.data;
  });
