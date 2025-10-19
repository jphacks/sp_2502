import { Box, HStack, VStack, Text } from "@chakra-ui/react";
import { useState } from "react";
import { FaAngleDown } from "react-icons/fa6";

import CardList from "@/app/_components/cards-list";
import { HydrateClient } from "@/trpc/server";

export type CardListItemType = {
  id: number;
  title: string;
  description: string;
};

export type SelectedItemType = {
  id: number;
  taskname: string;
  pretask: string[];
};

export default function Home() {
  const listA = [
    { id: 1, title: "カード1", description: "最初のカード" },
    { id: 2, title: "カード2", description: "2番目のカード" },
    { id: 3, title: "カード3", description: "3番目のカード" },
    { id: 4, title: "カード1", description: "最初のカード" },
    { id: 5, title: "カード2", description: "2番目のカード" },
    { id: 6, title: "カード3", description: "3番目のカード" },
    { id: 7, title: "カード1", description: "最初のカード" },
    { id: 8, title: "カード2", description: "2番目のカード" },
    { id: 9, title: "カード3", description: "3番目のカード" },
  ];

  const [selectedItem, setSelectedItem] = useState<SelectedItemType>({
    id: 0,
    taskname: "",
    pretask: [],
  });

  return (
    <HydrateClient>
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
                <VStack
                  key={item}
                  fontSize="40px"
                  color="#000000"
                  align="center">
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
            <CardList items={listA} onSelect={setSelectedItem} />
          </VStack>
        </Box>
      </HStack>
    </HydrateClient>
  );
}
