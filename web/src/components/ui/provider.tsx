"use client";

import {
  ChakraProvider,
  createSystem,
  defaultConfig,
  defineConfig,
} from "@chakra-ui/react";

import { ColorModeProvider, type ColorModeProviderProps } from "./color-mode";

const config = defineConfig({
  theme: {
    tokens: {
      fonts: {
        heading: { value: "'Mamelon', sans-serif" },
        body: { value: "'Mamelon', sans-serif" },
      },
    },
  },
});

export const system = createSystem(defaultConfig, config);

export function Provider({ children, ...props }: ColorModeProviderProps) {
  return (
    <ColorModeProvider {...props}>
      <ChakraProvider value={system}>{children}</ChakraProvider>
    </ColorModeProvider>
  );
}
