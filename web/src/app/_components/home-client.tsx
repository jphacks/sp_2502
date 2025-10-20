"use client";

import {
  Box,
  HStack,
  VStack,
  Text,
  Link,
  Image,
  Button,
} from "@chakra-ui/react";
import { useState } from "react";
import { FaAngleDown } from "react-icons/fa6";

import CardList from "@/app/_components/cards-list";
import type { TaskDTO } from "@/server/modules/task/_dto";
import { api } from "@/trpc/react";

import type { SessionData } from "@auth0/nextjs-auth0/types";

type HomeClientProps = {
  session: SessionData | null;
};

// ボタンクリックアニメーション定義
const bounceAnimation = `
  @keyframes buttonBounce {
    0% { transform: scale(1); }
    30% { transform: scale(0.85); }
    60% { transform: scale(1.1); }
    100% { transform: scale(1); }
  }
`;

export const HomeClient = ({ session }: HomeClientProps) => {
  const [taskSelect, setTaskSelect] = useState<TaskDTO | null>(null);
  const [isAnimating, setIsAnimating] = useState(false);

  const utils = api.useUtils();

  // アクティブタスクの一覧を取得
  const { data: activeTasksData } = api.task.activeList.useQuery({
    order: "desc",
  });

  // 選択されたタスクの親タスク情報を自動取得
  const { data: parentTasks } = api.task.select.useQuery(
    { task_id: taskSelect?.id ?? "" },
    { enabled: !!taskSelect }, // taskSelectがnullでない時のみクエリ実行
  );

  // タスク完了処理のmutation
  const completeTask = api.task.complete.useMutation();

  const handleSelectTask = (id: string) => {
    const task = activeTasksData?.tasks.find(t => t.id === id);
    if (task) {
      setTaskSelect(task); // これが変わると自動的に親タスクが取得される
    }
  };

  const handleTaskComplete = () => {
    if (!taskSelect) return;

    // アニメーションをトリガー
    setIsAnimating(true);
    setTimeout(() => setIsAnimating(false), 400);

    completeTask.mutate(
      {
        taskId: taskSelect.id,
      },
      {
        onSuccess: data => {
          // サーバーから次のタスクとアクティブタスク一覧を受け取る
          setTaskSelect(data.nextTask);
          // アクティブタスク一覧を更新
          void utils.task.activeList.invalidate();
        },
      },
    );
  };

  return (
    <>
      <style>{bounceAnimation}</style>
      <HStack w="100vw" h="100vh" gap="0px" bg="white" overflow="hidden">
        <Box bg="#EEEEEE" w="300px" minW="330px" h="full">
          <VStack h="full" ml="20px">
            <Button
              mt="33px"
              w="203px"
              h="192px"
              border="none"
              bg="transparent"
              onClick={handleTaskComplete}
              bgImage="url('/images/check-2.svg')"
              css={{
                animation: isAnimating
                  ? "buttonBounce 0.4s ease-in-out"
                  : "none",
              }}
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

            <Link
              mt="10px"
              bottom="0px"
              w="277px"
              h="79px"
              href="/auth/logout"
              bg="#FFBE45"
              borderTopRadius="15px"
              borderBottomRadius="0"
              display="flex"
              alignItems="center"
              justifyContent="center">
              <Text fontSize="40px" color="#000000">
                ログアウト
              </Text>
            </Link>
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
              justifyContent="start"
              px={3}
              py={2}
              bg="rgba(0,0,0,0.2)"
              borderRadius="8px">
              {session?.user && (
                <HStack gap={3} fontSize="14px" color="white">
                  <Image
                    src={session.user.picture ?? "/images/default-user.png"}
                    alt="User Avatar"
                    width="30px"
                    height="30px"
                    rounded="full"
                  />
                  <Text opacity={0.8}>
                    {session.user.name ?? session.user.email ?? "ユーザー"}
                  </Text>
                  <Link href="/auth/logout" color="#FFBE45" opacity={0.9}>
                    ログアウト
                  </Link>
                </HStack>
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
    </>
  );
};
