#!/bin/bash
# second-opinion exec - ワンショット実行

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# 全引数を結合
PROMPT="$*"

if [[ -z "$PROMPT" ]]; then
  echo "Error: プロンプトを指定してください" >&2
  echo "使用方法: /second-opinion exec <prompt>" >&2
  exit 1
fi

CODEX_CMD=$(get_codex_command) || exit 1

# セキュアな一時ファイル作成
OUTPUT_FILE=$(create_temp_file "so-output")
setup_cleanup_trap "$OUTPUT_FILE"

# ワンショット実行
if ! $CODEX_CMD exec $CODEX_COMMON_ARGS --output-last-message "$OUTPUT_FILE" "$PROMPT"; then
  echo "Error: codex の実行に失敗しました" >&2
  exit 1
fi

if [[ -f "$OUTPUT_FILE" ]] && [[ -s "$OUTPUT_FILE" ]]; then
  cat "$OUTPUT_FILE"
else
  echo "Error: 出力ファイルが生成されませんでした" >&2
  exit 1
fi
