import { createTRPCRouter } from "@/server/api/trpc";
import { activeListTasks } from "@/server/modules/task/activeList/endpoint.trpc";
import { completeTask } from "@/server/modules/task/complete/endpoint.trpc";
import { deleteTask } from "@/server/modules/task/delete/endpoint.trpc";
import { projectCreateTask } from "@/server/modules/task/projectCreate/endpoint.trpc";
import { selectTask } from "@/server/modules/task/select/endpoint.trpc";
import { statusUpdateTask } from "@/server/modules/task/statusUpdate/endpoint.trpc";
import { unprocessedListTasks } from "@/server/modules/task/unprocessedList/endpoint.trpc";

export const taskRouter = createTRPCRouter({
  activeList: activeListTasks,
  projectCreate: projectCreateTask,
  delete: deleteTask,
  statusUpdate: statusUpdateTask,
  select: selectTask,
  unprocessedList: unprocessedListTasks,
  complete: completeTask,
});
