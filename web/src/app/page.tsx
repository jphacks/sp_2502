import { Box, HStack, VStack, Text } from "@chakra-ui/react";
import { FaAngleDown } from "react-icons/fa6";

// import { Global } from "@emotion/react";
import CardList from "@/app/_components/cards-list";
// import { Provider } from "@/components/ui/provider";
import { getSession } from "@/server/auth/helpers";
import { HydrateClient } from "@/trpc/server";

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
    { id: 1, taskname: "キーワード決定" },
    { id: 2, taskname: "参考文献探し" },
    { id: 3, taskname: "心理学レポート" },
  ];

  // const session = await getSession();

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
                キーワード探し
              </Text>
            </Box>

            <Box flex="1" gap="0px" w="full" minH="50px" overflowY="auto">
              {listB.map(item => (
                <VStack
                  key={item.id}
                  fontSize="40px"
                  color="#000000"
                  align="center">
                  <FaAngleDown />
                  {item.taskname}
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
            <CardList items={listA} />
          </VStack>
        </Box>
      </HStack>
    </HydrateClient>
  );
}
