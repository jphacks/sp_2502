import { Box, Button, VStack, Text } from "@chakra-ui/react";
import Link from "next/link";

import { HomeClient } from "@/app/_components/home-client";
import { getSession } from "@/server/auth/helpers";
import { api, HydrateClient } from "@/trpc/server";

export default async function Home() {
  const session = await getSession();

  if (session?.user) {
    void api.note.list.prefetch({ limit: 50, offset: 0 });
  }

  // 認証失敗時：シンプルなログインボタンを表示
  if (!session?.user) {
    return (
      <Box
        w="100vw"
        h="100vh"
        display="flex"
        alignItems="center"
        justifyContent="center"
        bg="#860F0F">
        <VStack gap={6}>
          <Text fontSize="48px" fontWeight="bold" color="#FFBE45">
            タスクのカケラ
          </Text>
          <Button
            as={Link}
            href="/auth/login"
            size="lg"
            bg="#FFBE45"
            color="#000000"
            fontSize="24px"
            px={12}
            py={8}
            borderRadius="20px"
            _hover={{ bg: "#FFD166" }}
            _active={{ bg: "#FFAA00" }}>
            ログイン
          </Button>
        </VStack>
      </Box>
    );
  }

  return (
    <HydrateClient>
      <HomeClient />
    </HydrateClient>
  );
}
