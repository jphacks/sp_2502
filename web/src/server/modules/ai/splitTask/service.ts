import * as Sentry from "@sentry/nextjs";
import OpenAI from "openai";

import type { DBLike } from "@/server/db";
import type { SelectTask } from "@/server/db/schema/tasks";
import { updateTaskStatus } from "@/server/modules/task";
import { type ProjectId, TaskId, type UserId } from "@/server/types/brand";
import { type AppError, Errors } from "@/server/types/errors";
import { type AsyncResult, Err, Ok } from "@/server/types/result";
import type { Deps } from "@/server/utils/deps";

import {
  findProjectByTaskId,
  findTaskById,
  findTasksByProjectId,
  insertChildTask,
} from "../_repo";
import { inputSchema } from "./contract";

import type { Output, Request } from "./contract";

type TaskGraph = {
  [key: string]: TaskGraph;
};

const buildTaskGraph = (tasks: SelectTask[]): TaskGraph => {
  const taskMap = new Map<string, SelectTask>();
  const childrenMap = new Map<string, SelectTask[]>();

  for (const task of tasks) {
    taskMap.set(task.id, task);
    if (task.parentId) {
      const siblings = childrenMap.get(task.parentId) ?? [];
      siblings.push(task);
      childrenMap.set(task.parentId, siblings);
    }
  }

  const buildNode = (taskId: string): TaskGraph => {
    const task = taskMap.get(taskId);
    if (!task) return {};

    const children = childrenMap.get(taskId) ?? [];
    const childGraph: TaskGraph = {};

    for (const child of children) {
      childGraph[child.name] = buildNode(child.id);
    }

    return childGraph;
  };

  const graph: TaskGraph = {};
  for (const task of tasks) {
    if (!task.parentId) {
      graph[task.name] = buildNode(task.id);
    }
  }

  return graph;
};

const truncateToMaxLength = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength);
};

export const execute = async (
  deps: Deps,
  cmd: Request,
): AsyncResult<Output, AppError> => {
  const parsed = inputSchema.safeParse({
    ...cmd,
    userId: deps.authUserId,
    taskId: cmd.taskId,
  });
  if (!parsed.success) {
    return Err(Errors.validation("INVALID_INPUT", parsed.error.issues));
  }

  const userId = parsed.data.userId as UserId;
  const taskId = parsed.data.taskId as TaskId;

  const taskResult = await findTaskById(deps.db, taskId);
  if (!taskResult.success) return Err(taskResult.error);
  const task = taskResult.data;

  if (task.userId !== userId) {
    return Err(Errors.permission("FORBIDDEN"));
  }

  const projectResult = await findProjectByTaskId(deps.db, taskId);
  if (!projectResult.success) return Err(projectResult.error);
  const project = projectResult.data;

  const projectId = project.id as ProjectId;
  const tasksResult = await findTasksByProjectId(deps.db, projectId);
  if (!tasksResult.success) return Err(tasksResult.error);
  const tasks = tasksResult.data;

  const graph = buildTaskGraph(tasks);

  const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
  });

  let firstHalf: string;
  let secondHalf: string;

  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4.1-mini",
      messages: [
        {
          role: "system",
          content:
            'You are a task splitting assistant. As an AI, you are tasked with analyzing the request {{task}} and dividing the entire workflow into two primary sequential phases ("First Half" and "Second Half"). {{graph}} represents the complete workflow of the project, including {{task}}. Ensure that both first_half and second_half generate content that differs from {{graph}}. For first_half, describe the key phases of the initial work stages. For second_half, describe the remaining final stages of work required to complete the task. You must provide your response in the following JSON format and strictly adhere to the specified character limits: {"first_half": "[first_half (initial work phase). 15 characters or less]", "second_half": "[second_half (remaining final work phase to execute after first_half). 15 characters or less]"}',
        },
        {
          role: "user",
          content: `task: ${task.name}\ngraph: ${JSON.stringify(graph)}`,
        },
      ],
      response_format: { type: "json_object" },
      temperature: 0.7,
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      return Err(Errors.external("OPENAI_API_ERROR", "No response content"));
    }

    const parsed = JSON.parse(content) as {
      first_half: string;
      second_half: string;
    };
    firstHalf = truncateToMaxLength(parsed.first_half, 15);
    secondHalf = truncateToMaxLength(parsed.second_half, 15);
  } catch (e) {
    return Err(Errors.external("OPENAI_API_ERROR", e));
  }

  return Sentry.startSpan(
    {
      name: "ai.splitTask.execute",
      op: "db.tx",
    },
    async () =>
      deps.db.transaction(async tx => {
        const firstTaskResult = await insertChildTask(tx as DBLike, {
          userId,
          projectId,
          name: firstHalf,
          parentId: taskId,
        });

        if (!firstTaskResult.success) return Err(firstTaskResult.error);

        const secondTaskResult = await insertChildTask(tx as DBLike, {
          userId,
          projectId,
          name: secondHalf,
          parentId: taskId,
        });

        if (!secondTaskResult.success) return Err(secondTaskResult.error);

        await updateTaskStatus(tx as DBLike, {
          taskId,
          userId,
          status: "waiting",
        });

        return Ok({
          first_task_id: TaskId.parse(firstTaskResult.data.id),
          first_task_name: firstTaskResult.data.name,
          second_task_id: TaskId.parse(secondTaskResult.data.id),
          second_task_name: secondTaskResult.data.name,
        });
      }),
  );
};
