#!/bin/bash

# Claude Code PostToolUse Hook: 自動フォーマット&検証
# WriteまたはEditツール使用後に実行されます

set -e

# プロジェクトディレクトリに移動
cd "${CLAUDE_PROJECT_DIR:-.}"

# 標準入力からJSONを読み取る
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "Unknown"')

# WriteまたはEdit操作でない場合は何もしない
if [[ "$TOOL_NAME" != "Write" ]] && [[ "$TOOL_NAME" != "Edit" ]] && [[ "$TOOL_NAME" != "NotebookEdit" ]]; then
  exit 0
fi

# 一時ファイルに出力を保存
TEMP_OUTPUT=$(mktemp)
TEMP_DETAILS=$(mktemp)
trap "rm -f $TEMP_OUTPUT $TEMP_DETAILS" EXIT

echo "[PostEditCheck]" > "$TEMP_OUTPUT"

# TypeCheckを実行
if pnpm typecheck > "$TEMP_DETAILS" 2>&1; then
  echo "[1/3] TypeCheck: OK" >> "$TEMP_OUTPUT"
  TYPECHECK_OK=1
else
  echo "[1/3] TypeCheck: エラーが発生しました" >> "$TEMP_OUTPUT"
  cat "$TEMP_DETAILS" >> "$TEMP_OUTPUT"
  echo "---" >> "$TEMP_OUTPUT"
  TYPECHECK_OK=0
fi

# ESLint自動修正を実行
if pnpm lint:fix > "$TEMP_DETAILS" 2>&1; then
  echo "[2/3] ESLint: OK" >> "$TEMP_OUTPUT"
  LINT_OK=1
else
  echo "[2/3] ESLint: エラーが発生しました" >> "$TEMP_OUTPUT"
  cat "$TEMP_DETAILS" >> "$TEMP_OUTPUT"
  echo "---" >> "$TEMP_OUTPUT"
  LINT_OK=0
fi

# Prettierフォーマットを実行
if pnpm format > "$TEMP_DETAILS" 2>&1; then
  echo "[3/3] Prettier: OK" >> "$TEMP_OUTPUT"
  FORMAT_OK=1
else
  echo "[3/3] Prettier: エラーが発生しました" >> "$TEMP_OUTPUT"
  cat "$TEMP_DETAILS" >> "$TEMP_OUTPUT"
  echo "---" >> "$TEMP_OUTPUT"
  FORMAT_OK=0
fi

# 結果の集計
if [[ $TYPECHECK_OK -eq 1 ]] && [[ $LINT_OK -eq 1 ]] && [[ $FORMAT_OK -eq 1 ]]; then
  echo "✅ すべてのチェックに合格しました" >> "$TEMP_OUTPUT"

  # 成功時のJSON出力
  cat "$TEMP_OUTPUT" | jq -Rs '{
    decision: "approve",
    reason: "コード品質チェックに合格しました",
    systemMessage: .
  }'
  exit 0
else
  echo "" >> "$TEMP_OUTPUT"
  echo "❌ 一部のチェックが失敗しました。上記のエラーを確認し、修正してください。" >> "$TEMP_OUTPUT"

  # エラー時のJSON出力
  cat "$TEMP_OUTPUT" | jq -Rs '{
    decision: "block",
    reason: "コード品質チェックに失敗しました",
    systemMessage: .
  }'
  exit 2
fi
