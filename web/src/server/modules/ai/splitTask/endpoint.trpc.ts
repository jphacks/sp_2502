import { protectedProcedure } from "@/server/api/trpc";
import { UserId } from "@/server/types/brand";
import { toTrpcError } from "@/server/types/errors";
import { createAuthDeps } from "@/server/utils/deps";

import { request, response } from "./contract";
import { execute } from "./service";

export const splitTask = protectedProcedure
  .input(request)
  .output(response)
  .mutation(async ({ ctx, input }) => {
    const deps = createAuthDeps(ctx.db, UserId.parse(ctx.session.user.id));
    const result = await execute(deps, input);
    if (!result.success) throw toTrpcError(result.error);
    return result.data;
  });
