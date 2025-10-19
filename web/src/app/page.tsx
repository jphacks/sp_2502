import {
  Box,
  Button,
  Container,
  Heading,
  HStack,
  VStack,
  Stack,
  Text,
} from "@chakra-ui/react";
// import { Global } from "@emotion/react";
import { Provider } from "@/components/ui/provider"

import { Notes } from "@/app/_components/notes";
import { getSession } from "@/server/auth/helpers";
import { api, HydrateClient } from "@/trpc/server";
import CardList from "@/app/_components/cards-list";

export default async function Home() {
  const listA = [
    { id: 1, title: "カード1", description: "最初のカード" },
    { id: 2, title: "カード2", description: "2番目のカード" },
    { id: 3, title: "カード3", description: "3番目のカード" },
    { id: 1, title: "カード1", description: "最初のカード" },
    { id: 2, title: "カード2", description: "2番目のカード" },
    { id: 3, title: "カード3", description: "3番目のカード" },
    { id: 1, title: "カード1", description: "最初のカード" },
    { id: 2, title: "カード2", description: "2番目のカード" },
    { id: 3, title: "カード3", description: "3番目のカード" },
  ];
  const listB = [
    { id: 1, taskname: "キーワード決定"},
    { id: 2, taskname: "参考文献探し"},
    { id: 3, taskname: "心理学レポート"},
  ];
  
  const session = await getSession();

  return(
    <Provider>
    <HydrateClient>
        <HStack w="100vw" h="100vh" gap="0px" bg="white" overflow="hidden">
          <Box bg="#EEEEEE" w="300px" minW="330px" h="full" >
            <VStack h="full" ml="20px">
              <Box mt="33px" w="185px" h="185px" border="none" bgImage="url('/images/check.svg')"/>
              <Box mt="22px" w="278px" h="175px" bg="transparent" borderRadius="0" border="none" bgImage="url('/images/choco.svg')" display="flex" alignItems="center" justifyContent="center">
                <Text fontSize="32px" color="#FFBE45">キーワード探し</Text>
              </Box>

              <Box flex="1" gap="0px" w="full" minH="50px" overflowY="auto">
                {listB.map((item) => (
                  <VStack key={item.id} fontSize="40px" color="#000000" align="center">
                    <FaAngleDown/>
                    {item.taskname}
                  </VStack>
                ))}
              </Box>

              <Box mt="10px" bottom="0px" w="277px" h="79px" bg="#FFBE45"  borderTopRadius="15px" borderBottomRadius="0" display="flex" alignItems="center" justifyContent="center">
                <Text fontSize="40px" color="#000000">タスク追加</Text>
              </Box>
            </VStack>
          </Box>

          <Box h="full" w="75.4px" bg="#EEEEEE" bgImage="url('/images/wave-2.svg')"></Box>
{/* bgImage="url('/images/bg-red.svg')" */}
          <Box flex="1" bg="#860F0F"  minW="300px" h="full" overflowY="auto" p={5}>
            <VStack w="full" h="full" gap={10}>
              <Box bg="#A60000" w="100%" maxW="600px" h="auto" minH="130px" borderRadius="40px" display="flex" alignItems="center" justifyContent="center" >
                <Text fontSize="clamp(1px, 4vw, 60px)" color="#FFBE45">タスクのカケラ</Text>
              </Box>
              <CardList items={listA}/>
            </VStack>
          </Box>
        </HStack>
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
                    {session.user.name ??
                      session.user.nickname ??
                      session.user.email ??
                      "ユーザー"}
                  </Text>
                  <Button
                    asChild
                    rounded="lg"
                    bg="whiteAlpha.200"
                    fontWeight="semibold"
                    _hover={{ bg: "whiteAlpha.300" }}>
                    <Link href="/auth/logout" prefetch={false}>
                      ログアウト
                    </Link>
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
                <Link href="/auth/login">ログイン</Link>
              </Button>
            </Stack>
          )}
        </Container>
      </Box>
    </HydrateClient>
    </Provider>
  );
}

