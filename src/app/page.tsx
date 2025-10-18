import {
  Box,
  Button,
  Container,
  Heading,
  HStack,
  Stack,
  Text,
} from "@chakra-ui/react";
import Link from "next/link";

import { Notes } from "@/app/_components/notes";
import { auth } from "@/server/auth";
import { api, HydrateClient } from "@/trpc/server";

export default async function Home() {
  const session = await auth();

  if (session?.user) {
    void api.note.list.prefetch({ limit: 50, offset: 0 });
  }

  return (
    <HydrateClient>
      <Box
        minH="100vh"
        bgGradient="to-b"
        gradientFrom="purple.900"
        gradientTo="gray.900"
        color="white">
        {/* ヘッダー */}
        <Box
          borderBottomWidth="1px"
          borderColor="whiteAlpha.200"
          bg="whiteAlpha.100">
          <Container maxW="container.xl">
            <HStack justify="space-between" py={4}>
              <Heading size="xl" fontWeight="bold">
                Note App
              </Heading>
              {session?.user && (
                <HStack gap={4}>
                  <Text color="whiteAlpha.800">
                    {session.user.name ?? session.user.email}
                  </Text>
                  <Button
                    asChild
                    rounded="lg"
                    bg="whiteAlpha.200"
                    fontWeight="semibold"
                    _hover={{ bg: "whiteAlpha.300" }}>
                    <Link href="/api/auth/signout">ログアウト</Link>
                  </Button>
                </HStack>
              )}
            </HStack>
          </Container>
        </Box>

        {/* メインコンテンツ */}
        <Container maxW="container.xl" py={12}>
          {session?.user ? (
            <Notes />
          ) : (
            <Stack align="center" gap={8} py={16}>
              <Heading size="4xl" fontWeight="bold">
                ようこそ！
              </Heading>
              <Text color="whiteAlpha.800" textAlign="center" textStyle="xl">
                Noteアプリを使用するにはログインしてください
              </Text>
              <Button
                asChild
                rounded="lg"
                bg="whiteAlpha.900"
                px={8}
                py={4}
                fontWeight="semibold"
                fontSize="lg"
                _hover={{ bg: "whiteAlpha.300" }}>
                <Link href="/api/auth/signin">ログイン</Link>
              </Button>
            </Stack>
          )}
        </Container>
      </Box>
    </HydrateClient>
  );
}
