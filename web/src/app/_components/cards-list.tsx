"use client";

import {
  Wrap,
  WrapItem,
  Card,
  CardHeader,
  CardBody,
  Heading,
  Text,
  Center,
} from "@chakra-ui/react";
import { Chocolate_Classical_Sans } from "next/font/google";

// export default function CardList({ items }) {
//   return (
//     <SimpleGrid columns={[1, 2, 3]} gap={2}>
//       {items.map((item) => (
//         <Card key={item.id} shadow="md" borderRadius="xl" bg="white">
//           <CardHeader>
//             <Heading size="md">{item.title}</Heading>
//           </CardHeader>
//           <CardBody>
//             <Text>{item.description}</Text>
//           </CardBody>
//         </Card>
//       ))}
//     </SimpleGrid>
//   );
// }

type Item = {
  id: number;
  title: string;
  description: string;
};

type CardListProps = {
  items: Item[];
};

export default function CardList({ items }: CardListProps) {
  return (
    <Wrap gap="40px" justifyContent="center">
      {items.map((item) => (
        <WrapItem key={item.id}>
            <Card.Root
              w="268px"
              h="165px"
              border="none"
              bgImage="url('/images/choco.svg')"
            >
            {/* <CardHeader>
              <Heading size="md">{item.title}</Heading>
            </CardHeader> */}
            <CardBody
              display="flex"
              alignItems="center"
              justifyContent="center"
            >
              <Text fontSize="32px" color="#FFBE45">{item.description}</Text>
            </CardBody>
          </Card.Root>
        </WrapItem>
      ))}
    </Wrap>
  );
}