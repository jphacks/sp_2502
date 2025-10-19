"use client";

import { Wrap, WrapItem, Card, CardBody, Text } from "@chakra-ui/react";

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
  taskname: string;
  pretask: string[];
};

type CardListProps = {
  items: Item[];
  onSelect: (pretask: string[]) => void;
};

export default function CardList({ items }: CardListProps) {
  return (
    <Wrap gap="40px" justifyContent="center">
      {items.map(item => (
        <WrapItem key={item.id}>
          <Card.Root
            as="button"
            w="278px"
            h="175px"
            bg="transparent"
            borderRadius="0"
            border="none"
            bgImage="url('/images/choco.svg')">
            onClick={() => onSelect(item.pretask)}
            {/* <CardHeader>
              <Heading size="md">{item.title}</Heading>
            </CardHeader> */}
            <CardBody
              display="flex"
              alignItems="center"
              justifyContent="center">
              <Text fontSize="32px" color="#FFBE45">
                {item.taskname}
              </Text>
            </CardBody>
          </Card.Root>
        </WrapItem>
      ))}
    </Wrap>
  );
}
