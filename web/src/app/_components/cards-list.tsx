"use client";

import { Wrap, WrapItem, Card, CardBody, Text } from "@chakra-ui/react";

import type { TaskDTO } from "@/server/modules/task/_dto";

type CardListProps = {
  items: TaskDTO[];
  onSelect: (id: string) => void;
};

export default function CardList({ items, onSelect }: CardListProps) {
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
            bgImage="url('/images/choco.svg')"
            cursor="pointer"
            onClick={() => onSelect(item.id)}>
            <CardBody
              display="flex"
              alignItems="center"
              justifyContent="center">
              <Text fontSize="32px" color="#FFBE45">
                {item.name}
              </Text>
            </CardBody>
          </Card.Root>
        </WrapItem>
      ))}
    </Wrap>
  );
}
