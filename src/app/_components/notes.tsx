"use client";

import {
  Box,
  Button,
  Card,
  Field,
  Heading,
  HStack,
  Input,
  Stack,
  Text,
  Textarea,
} from "@chakra-ui/react";
import { useState } from "react";

import { api } from "@/trpc/react";

export const Notes = () => {
  const [notes] = api.note.list.useSuspenseQuery({ limit: 50, offset: 0 });

  const utils = api.useUtils();
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");

  // 編集モード用の状態
  const [editingNoteId, setEditingNoteId] = useState<string | null>(null);
  const [editTitle, setEditTitle] = useState("");
  const [editContent, setEditContent] = useState("");

  const createNote = api.note.create.useMutation({
    onSuccess: async () => {
      await utils.note.invalidate();
      setTitle("");
      setContent("");
    },
  });

  const updateNote = api.note.update.useMutation({
    onSuccess: async () => {
      await utils.note.invalidate();
      setEditingNoteId(null);
      setEditTitle("");
      setEditContent("");
    },
  });

  const deleteNote = api.note.delete.useMutation({
    onSuccess: async () => {
      await utils.note.invalidate();
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (title.trim() && content.trim()) {
      createNote.mutate({ title: title.trim(), content: content.trim() });
    }
  };

  const handleEditClick = (
    noteId: string,
    currentTitle: string,
    currentContent: string,
  ) => {
    setEditingNoteId(noteId);
    setEditTitle(currentTitle);
    setEditContent(currentContent);
  };

  const handleEditCancel = () => {
    setEditingNoteId(null);
    setEditTitle("");
    setEditContent("");
  };

  const handleEditSubmit = (noteId: string) => {
    if (editTitle.trim() && editContent.trim()) {
      updateNote.mutate({
        noteId,
        title: editTitle.trim(),
        content: editContent.trim(),
      });
    }
  };

  const handleDeleteClick = (noteId: string) => {
    if (window.confirm("このNoteを削除してもよろしいですか？")) {
      deleteNote.mutate({ noteId });
    }
  };

  return (
    <Stack gap={8} w="full" maxW="4xl" mx="auto">
      {/* Note作成フォーム */}
      <Card.Root bg="whiteAlpha.200">
        <Card.Body>
          <Heading size="xl" mb={4} fontWeight="bold">
            新しいNoteを作成
          </Heading>
          <form onSubmit={handleSubmit}>
            <Stack gap={4}>
              <Field.Root>
                <Input
                  placeholder="タイトル"
                  value={title}
                  onChange={e => setTitle(e.target.value)}
                  bg="whiteAlpha.200"
                  color="white"
                  _placeholder={{ color: "whiteAlpha.600" }}
                  rounded="lg"
                  maxLength={100}
                />
              </Field.Root>
              <Field.Root>
                <Textarea
                  placeholder="内容"
                  value={content}
                  onChange={e => setContent(e.target.value)}
                  bg="whiteAlpha.200"
                  color="white"
                  _placeholder={{ color: "whiteAlpha.600" }}
                  rounded="lg"
                  rows={4}
                  maxLength={10000}
                />
              </Field.Root>
              <Button
                type="submit"
                w="full"
                bg="whiteAlpha.200"
                fontWeight="semibold"
                rounded="lg"
                _hover={{ bg: "whiteAlpha.300" }}
                disabled={
                  createNote.isPending || !title.trim() || !content.trim()
                }>
                {createNote.isPending ? "作成中..." : "作成"}
              </Button>
            </Stack>
          </form>
        </Card.Body>
      </Card.Root>

      {/* Note一覧 */}
      <Stack gap={4}>
        <Heading size="xl" fontWeight="bold">
          Noteリスト
        </Heading>
        {notes.notes.length === 0 ? (
          <Box
            bg="whiteAlpha.100"
            p={8}
            rounded="lg"
            textAlign="center"
            color="whiteAlpha.700">
            まだNoteがありません。上のフォームから作成してください。
          </Box>
        ) : (
          <Stack gap={4}>
            {notes.notes.map(note => {
              const isEditing = editingNoteId === note.id;

              return (
                <Card.Root
                  key={note.id}
                  bg="whiteAlpha.200"
                  _hover={{ bg: "whiteAlpha.250" }}
                  transition="background 0.2s">
                  <Card.Body>
                    {isEditing ? (
                      // 編集モード
                      <Stack gap={4}>
                        <Field.Root>
                          <Input
                            value={editTitle}
                            onChange={e => setEditTitle(e.target.value)}
                            bg="whiteAlpha.200"
                            color="white"
                            _placeholder={{ color: "whiteAlpha.600" }}
                            rounded="lg"
                            maxLength={100}
                            placeholder="タイトル"
                          />
                        </Field.Root>
                        <Field.Root>
                          <Textarea
                            value={editContent}
                            onChange={e => setEditContent(e.target.value)}
                            bg="whiteAlpha.200"
                            color="white"
                            _placeholder={{ color: "whiteAlpha.600" }}
                            rounded="lg"
                            rows={4}
                            maxLength={10000}
                            placeholder="内容"
                          />
                        </Field.Root>
                        <HStack gap={2}>
                          <Button
                            onClick={() => handleEditSubmit(note.id)}
                            bg="whiteAlpha.200"
                            fontWeight="semibold"
                            rounded="lg"
                            _hover={{ bg: "whiteAlpha.300" }}
                            disabled={
                              updateNote.isPending ||
                              !editTitle.trim() ||
                              !editContent.trim()
                            }>
                            {updateNote.isPending ? "保存中..." : "保存"}
                          </Button>
                          <Button
                            onClick={handleEditCancel}
                            bg="whiteAlpha.100"
                            fontWeight="semibold"
                            rounded="lg"
                            _hover={{ bg: "whiteAlpha.200" }}
                            disabled={updateNote.isPending}>
                            キャンセル
                          </Button>
                        </HStack>
                      </Stack>
                    ) : (
                      // 表示モード
                      <>
                        <HStack
                          justify="space-between"
                          align="flex-start"
                          mb={2}>
                          <Heading size="lg" fontWeight="bold">
                            {note.title}
                          </Heading>
                          <HStack gap={2}>
                            <Button
                              onClick={() =>
                                handleEditClick(
                                  note.id,
                                  note.title,
                                  note.content,
                                )
                              }
                              size="sm"
                              bg="whiteAlpha.200"
                              fontWeight="semibold"
                              rounded="lg"
                              _hover={{ bg: "whiteAlpha.300" }}>
                              編集
                            </Button>
                            <Button
                              onClick={() => handleDeleteClick(note.id)}
                              size="sm"
                              bg="red.500/20"
                              color="red.200"
                              fontWeight="semibold"
                              rounded="lg"
                              _hover={{ bg: "red.500/30" }}
                              disabled={deleteNote.isPending}>
                              削除
                            </Button>
                          </HStack>
                        </HStack>
                        <Text
                          mb={4}
                          whiteSpace="pre-wrap"
                          color="whiteAlpha.900">
                          {note.content}
                        </Text>
                        <Text color="whiteAlpha.500" fontSize="sm">
                          作成日時:{" "}
                          {new Date(note.createdAt).toLocaleString("ja-JP")}
                        </Text>
                      </>
                    )}
                  </Card.Body>
                </Card.Root>
              );
            })}
          </Stack>
        )}
      </Stack>
    </Stack>
  );
};
