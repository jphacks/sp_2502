import { createTRPCRouter } from "@/server/api/trpc";
import { activeListTasks } from "@/server/modules/task/activeList/endpoint.trpc";
import { deleteTask } from "@/server/modules/task/delete/endpoint.trpc";
import { projectCreateTask } from "@/server/modules/task/projectCreate/endpoint.trpc";
import { statusUpdateTask } from "@/server/modules/task/statusUpdate/endpoint.trpc";

export const taskRouter = createTRPCRouter({
  activeList: activeListTasks,
  projectCreate: projectCreateTask,
  delete: deleteTask,
  statusUpdate: statusUpdateTask,
});
