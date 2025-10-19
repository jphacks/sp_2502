"use client";

import { Box, HStack, VStack, Text } from "@chakra-ui/react";
import { useState } from "react";
import { FaAngleDown } from "react-icons/fa6";

import CardList from "@/app/_components/cards-list";
import type { TaskDTO } from "@/server/modules/task/_dto";
import { api } from "@/trpc/react";

export type SelectedItemType = {
  id: string;
  taskname: string;
  pretask: string[];
};

export default function Home() {
  const [selectedItem, setSelectedItem] = useState<SelectedItemType>({
    id: "",
    taskname: "",
    pretask: [],
  });

  // アクティブタスクの一覧を取得
  const { data: activeTasksData } = api.task.activeList.useQuery({
    order: "desc",
  });

  // タスク選択時に親タスク情報を取得
  // NOTE: task.selectエンドポイントは未実装のため、型アサーションを使用
  const selectMutation = (api.task as Record<string, unknown>).select as {
    useMutation: () => {
      mutateAsync: (input: { task_id: string }) => Promise<TaskDTO[]>;
    };
  };

  const handleSelectTask = async (childTask: TaskDTO) => {
    try {
      // task.select APIを呼び出し（rootから順に取得される）
      const tasks = await selectMutation.useMutation().mutateAsync({
        task_id: childTask.id,
      });

      if (tasks.length < 2) {
        // 親タスクがない場合（ルートタスク自身の場合）
        setSelectedItem({
          id: childTask.id,
          taskname: childTask.name,
          pretask: [],
        });
        return;
      }

      // tasks = [rootTask, ..., grandparent, parentTask, childTask]
      // 親タスク = 後ろから2番目
      const parentTask = tasks[tasks.length - 2];
      // 前提タスク = ルートから親の親まで
      const prerequisiteTasks = tasks.slice(0, -2);

      if (!parentTask) {
        return;
      }

      setSelectedItem({
        id: parentTask.id,
        taskname: parentTask.name,
        pretask: prerequisiteTasks.map((t: TaskDTO) => t.name),
      });
    } catch (error) {
      console.error("Failed to fetch parent task:", error);
    }
  };

  return (
    <HStack w="100vw" h="100vh" gap="0px" bg="white" overflow="hidden">
      <Box bg="#EEEEEE" w="300px" minW="330px" h="full">
        <VStack h="full" ml="20px">
          <Box
            mt="33px"
            w="185px"
            h="185px"
            border="none"
            bgImage="url('/images/check.svg')"
          />
          <Box
            mt="22px"
            w="278px"
            h="175px"
            bg="transparent"
            borderRadius="0"
            border="none"
            bgImage="url('/images/choco.svg')"
            display="flex"
            alignItems="center"
            justifyContent="center">
            <Text fontSize="32px" color="#FFBE45">
              {selectedItem.taskname}
            </Text>
          </Box>

          <Box flex="1" gap="0px" w="full" minH="50px" overflowY="auto">
            {selectedItem.pretask.map(item => (
              <VStack key={item} fontSize="40px" color="#000000" align="center">
                <FaAngleDown />
                {item}
              </VStack>
            ))}
          </Box>

          <Box
            mt="10px"
            bottom="0px"
            w="277px"
            h="79px"
            bg="#FFBE45"
            borderTopRadius="15px"
            borderBottomRadius="0"
            display="flex"
            alignItems="center"
            justifyContent="center">
            <Text fontSize="40px" color="#000000">
              タスク追加
            </Text>
          </Box>
        </VStack>
      </Box>
      <Box
        h="full"
        w="75.4px"
        bg="#EEEEEE"
        bgImage="url('/images/wave-2.svg')"></Box>
      {/* bgImage="url('/images/bg-red.svg')" */}
      <Box flex="1" bg="#860F0F" minW="300px" h="full" overflowY="auto" p={5}>
        <VStack w="full" h="full" gap={10}>
          {/* 認証バー */}
          {/* <HStack
            w="100%"
            justifyContent="flex-end"
            px={4}
            py={2}
            bg="rgba(0,0,0,0.2)"
            borderRadius="8px">
            {session?.user ? (
              <HStack gap={3} fontSize="14px" color="white">
                <Text opacity={0.8}>
                  {session.user.name ?? session.user.email ?? "ユーザー"}
                </Text>
                <Link href="/auth/logout" color="#FFBE45" opacity={0.9}>
                  ログアウト
                </Link>
              </HStack>
            ) : (
              <Link
                href="/auth/login"
                fontSize="14px"
                color="#FFBE45"
                opacity={0.9}>
                ログイン
              </Link>
            )}
          </HStack> */}

          <Box
            bg="#A60000"
            w="100%"
            maxW="600px"
            h="auto"
            minH="130px"
            borderRadius="40px"
            display="flex"
            alignItems="center"
            justifyContent="center">
            <Text fontSize="clamp(1px, 4vw, 60px)" color="#FFBE45">
              タスクのカケラ
            </Text>
          </Box>
          <CardList
            items={
              (activeTasksData as { tasks: TaskDTO[] } | undefined)?.tasks ?? []
            }
            onSelect={handleSelectTask}
          />
        </VStack>
      </Box>
    </HStack>
  );
}
