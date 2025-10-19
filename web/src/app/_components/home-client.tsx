"use client";

import { Box, HStack, VStack, Text, Link } from "@chakra-ui/react";
import { useState } from "react";
import { FaAngleDown } from "react-icons/fa6";

import CardList from "@/app/_components/cards-list";
import { getSession } from "@/server/auth/helpers";
import type { TaskDTO } from "@/server/modules/task/_dto";
import { api } from "@/trpc/react";

const session = await getSession();

export const HomeClient = () => {
  const [parentTasks, setParentTasks] = useState<TaskDTO[] | null>(null);
  const [taskSelect, setTaskSelect] = useState<TaskDTO | null>(null);

  // アクティブタスクの一覧を取得（モックデータ）
  const { data: activeTasksData } = api.task.activeList.useQuery({
    order: "desc",
  });

  // タスク選択時に親タスク情報を取得（モック実装）
  // NOTE: task.selectエンドポイントは未実装のため、モックデータを使用
  const handleSetParentTasks = (childTask: TaskDTO) => {
    try {
      const { data: taskData } = api.task.select.useQuery({
        task_id: childTask.id,
      });

      if (!taskData) {
        console.error("タスクデータが取得できませんでした");
        return;
      }

      setParentTasks(taskData);
    } catch (error) {
      console.error("タスクの取得に失敗しました:", error);
    }
  };

  const handleSelectTask = (id: string) => {
    const task = activeTasksData?.tasks.find(t => t.id === id);
    if (task) {
      setTaskSelect(task);
      handleSetParentTasks(task);
    }
  };

  return (
    <HStack w="100vw" h="100vh" gap="0px" bg="white" overflow="hidden">
      <Box bg="#EEEEEE" w="300px" minW="330px" h="full">
        <VStack h="full" ml="20px">
          <Box
            mt="33px"
            w="203px"
            h="192px"
            border="none"
            bgImage="url('/images/check-2.svg')"
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
              {taskSelect?.name ?? "タスクを選択してください"}
            </Text>
          </Box>

          <Box flex="1" gap="0px" w="full" minH="50px" overflowY="auto">
            {parentTasks?.map(item => (
              <VStack
                key={item.id}
                fontSize="40px"
                color="#000000"
                align="center">
                <FaAngleDown />
                {item.name}
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
              ログアウト
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
          <HStack
            w="100%"
            justifyContent="flex-end"
            px={4}
            py={2}
            bg="rgba(0,0,0,0.2)"
            borderRadius="8px">
            {session?.user.n ? (
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
          </HStack>

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
            items={activeTasksData?.tasks ?? []}
            onSelect={handleSelectTask}
          />
        </VStack>
      </Box>
    </HStack>
  );
};
