import { Box, Button, VStack, Text, Image } from "@chakra-ui/react";
import Link from "next/link";

import { HomeClient } from "@/app/_components/home-client";
import { getSession } from "@/server/auth/helpers";
import { HydrateClient } from "@/trpc/server";

export default async function Home() {
  const session = await getSession();

  // 認証失敗時：シンプルなログインボタンを表示
  if (!session?.user) {
    return (
      <HydrateClient>
        <VStack
          w="100vw"
          bg="#fff"
          alignItems="center"
          justifyContent="center"
          position="relative"
          h="100vh">
          <Image
            src="/images/logo.png"
            alt="Logo"
            w="350px"
            objectFit="contain"
            h="300px"
          />
          <Image
            src="/images/choco.svg"
            alt="Logo"
            w="100px"
            left="35%"
            top="25%"
            rotate="-20deg"
            position="absolute"
          />
          <Image
            src="/images/choco.svg"
            alt="Logo"
            w="100px"
            right="35%"
            bottom="40%"
            rotate="20deg"
            position="absolute"
          />
          <Link href="/auth/login">
            <Button
              size="lg"
              bg="#860F0F"
              color="#fff"
              fontSize="24px"
              px={12}
              py={8}
              borderRadius="20px"
              _hover={{ bg: "#b01c1cff" }}>
              ログイン
            </Button>
          </Link>
        </VStack>
      </HydrateClient>
    );
  }

  return (
    <HydrateClient>
      <HomeClient session={session} />
    </HydrateClient>
  );
}
