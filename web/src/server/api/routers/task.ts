import { createTRPCRouter } from "@/server/api/trpc";
import { activeListTasks } from "@/server/modules/task/activeList/endpoint.trpc";
import { projectCreateTask } from "@/server/modules/task/projectCreate/endpoint.trpc";

export const taskRouter = createTRPCRouter({
  activeList: activeListTasks,
  projectCreate: projectCreateTask,
});
