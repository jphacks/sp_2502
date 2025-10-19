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
import { FaAngleDown } from "react-icons/fa6";
import { auth } from "@/server/auth";
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
    { id: 4, taskname: "心理学レポート"},
    { id: 5, taskname: "心理学レポート"},
    { id: 6, taskname: "心理学レポート"},
    { id: 7, taskname: "心理学レポート"},
    { id: 8, taskname: "心理学レポート"},
    { id: 9, taskname: "心理学レポート"},
  ];

  return(
    <HydrateClient>
        <HStack w="100vw" h="100vh" gap={0} bg="white">
          <Box bg="white" w="300px" minW="300px" h="full" >
            <VStack mt="33px" h="full">
              <Box w="185px" h="185px" border="none" bgImage="url('/images/check.svg')"/>
              <Box mt="22px" w="268px" h="165px" border="none" bgImage="url('/images/choco.svg')" display="flex" alignItems="center" justifyContent="center">
                <Text fontSize="32px" color="#FFBE45">キーワード探し</Text>
              </Box>

              <Box flex="1" gap="5px" w="full" minH="200px" overflowY="auto">
                {listB.map((item) => (
                  <VStack key={item.id} fontSize="40px" color="#000000" align="center">
                    <FaAngleDown/>
                    {item.taskname}
                  </VStack>
                ))}
              </Box>

              <Box  mb="48px" mt="10px" bottom="0px" w="277px" h="79px" bg="#FFBE45"  borderRadius="15px" display="flex" alignItems="center" justifyContent="center">
                <Text fontSize="40px" color="#000000">タスク追加</Text>
              </Box>
            </VStack>
          </Box>
          <Box flex="1" bg="#960000" minW="300px" h="full" overflowY="auto" p={5}>
            <VStack w="full" h="full" gap={10}>
              <Box bg="#A60000" w="100%" maxW="600px" h="auto" minH="130px" borderRadius="40px" display="flex" alignItems="center" justifyContent="center" >
                <Text fontSize="clamp(1px, 5vw, 60px)" color="#FFBE45">タスクのカケラ</Text>
              </Box>
              <CardList items={listA}/>
            </VStack>
          </Box>
        </HStack>
    </HydrateClient>
  );
}

