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
          bg="#860F0F"
          alignItems="center"
          justifyContent="center"
          position="relative"
          h="100vh">
          <Image
            src="/images/logo-bg.png"
            alt="Logo"
            w="auto"
            maxWidth="650px"
            left="50%"
            top="50%"
            z-index={10}
            style={{ transform: "translate(-50%,-50%)" }}
            position="absolute"
          />
          <Image
            src="/images/choco.svg"
            alt="Logo"
            w="100px"
            left="35%"
            top="35%"
            rotate="-20deg"
            position="absolute"
            z-index={20}
          />
          <Image
            src="/images/choco.svg"
            alt="Logo"
            w="100px"
            right="35%"
            bottom="40%"
            rotate="20deg"
            z-index={20}
            position="absolute"
          />
          <Image
            src="/images/logo.png"
            alt="Logo"
            w="350px"
            objectFit="contain"
            z-index={30}
            h="300px"
            style={{ transform: "translate(-50%,-50%)" }}
            left="50%"
            top="50%"
            position="absolute"
          />
          <Link href="/auth/login">
            <Button
              position="absolute"
              z-index={30}
              size="lg"
              bg="#860F0F"
              color="#fff"
              fontSize="24px"
              px={12}
              py={8}
              borderRadius="20px"
              style={{ transform: "translate(-50%, 150%)" }}
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
