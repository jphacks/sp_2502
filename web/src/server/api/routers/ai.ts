import { createTRPCRouter } from "@/server/api/trpc";
import { splitTask } from "@/server/modules/ai/splitTask/endpoint.trpc";

export const aiRouter = createTRPCRouter({
  splitTask,
});
