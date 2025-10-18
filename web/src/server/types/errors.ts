import { TRPCError } from "@trpc/server";

export type ErrorKind =
  | "validation"
  | "domain"
  | "not_found"
  | "conflict"
  | "auth"
  | "permission"
  | "infra_db"
  | "infra_external"
  | "unknown";

export type AppError = {
  kind: ErrorKind;
  code: string; // 機械判定用コード
  message?: string; // 内部向け
  safeMessage?: string; // 外部向け
  details?: unknown; // ZodIssue[] 等
  cause?: unknown; // 生Errorやpgエラー
};

// ファクトリ
export const Errors = {
  validation: (code: string, details?: unknown): AppError => ({
    kind: "validation",
    code,
    details,
    safeMessage: "invalid input",
  }),
  notFound: (code = "NOT_FOUND"): AppError => ({
    kind: "not_found",
    code,
    safeMessage: "not found",
  }),
  conflict: (code = "CONFLICT"): AppError => ({
    kind: "conflict",
    code,
    safeMessage: "conflict",
  }),
  auth: (code = "UNAUTHORIZED"): AppError => ({
    kind: "auth",
    code,
    safeMessage: "unauthorized",
  }),
  permission: (code = "FORBIDDEN"): AppError => ({
    kind: "permission",
    code,
    safeMessage: "forbidden",
  }),
  infraDb: (code: string, cause?: unknown): AppError => ({
    kind: "infra_db",
    code,
    cause,
    safeMessage: "database error",
  }),
  external: (code: string, cause?: unknown): AppError => ({
    kind: "infra_external",
    code,
    cause,
    safeMessage: "upstream error",
  }),
  unknown: (cause?: unknown): AppError => ({
    kind: "unknown",
    code: "UNKNOWN",
    cause,
    safeMessage: "internal error",
  }),
};

export type TrpcCode =
  | "BAD_REQUEST"
  | "UNAUTHORIZED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "CONFLICT"
  | "TOO_MANY_REQUESTS"
  | "INTERNAL_SERVER_ERROR";

export const toTrpcCode = (kind: ErrorKind): TrpcCode => {
  switch (kind) {
    case "validation":
      return "BAD_REQUEST";
    case "auth":
      return "UNAUTHORIZED";
    case "permission":
      return "FORBIDDEN";
    case "not_found":
      return "NOT_FOUND";
    case "conflict":
      return "CONFLICT";
    default:
      return "INTERNAL_SERVER_ERROR";
  }
};

export const toTrpcError = (e: AppError): TRPCError =>
  new TRPCError({
    code: toTrpcCode(e.kind),
    message: e.safeMessage ?? e.code,
    cause: e.cause ?? e.details,
  });
