import { Auth0Provider } from "@auth0/nextjs-auth0/client";

import { Provider } from "@/components/ui/provider";
import { TRPCReactProvider } from "@/trpc/react";

import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "タスクネ",
  description: "パキッとクネクネタスク",
  icons: [{ rel: "icon", url: "/favicon.ico" }],
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ja" suppressHydrationWarning>
      <body className="light">
        <Auth0Provider>
          <Provider>
            <TRPCReactProvider>{children}</TRPCReactProvider>
          </Provider>
        </Auth0Provider>
      </body>
    </html>
  );
}
