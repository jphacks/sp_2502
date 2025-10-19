import { createTRPCRouter } from "@/server/api/trpc";
import { activeListTasks } from "@/server/modules/task/activeList/endpoint.trpc";

export const taskRouter = createTRPCRouter({
  activeList: activeListTasks,
});
