#!/bin/bash
# second-opinion ask - プロンプト送信

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# --help オプション
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "使用方法: /second-opinion ask [OPTIONS] <prompt>"
  echo ""
  echo "引数:"
  echo "  <prompt>    codexに送信するプロンプト"
  echo ""
  echo "オプション:"
  echo "  --help, -h  このヘルプを表示"
  echo ""
  echo "例:"
  echo "  /second-opinion ask このコードをレビューして"
  echo "  echo 'プロンプト' | /second-opinion ask  # stdin から読み込み"
  exit 0
fi

# 全引数を結合（スペース含むプロンプト対応）
PROMPT="$*"

# 引数がない場合は stdin から読み込み
if [[ -z "$PROMPT" ]]; then
  if [[ -t 0 ]]; then
    # stdin が端末の場合（パイプではない）
    echo "Error: プロンプトを指定してください" >&2
    echo "使用方法: /second-opinion ask <prompt>" >&2
    echo "または: echo 'プロンプト' | /second-opinion ask" >&2
    exit 1
  else
    # stdin からパイプで入力
    PROMPT=$(cat)
  fi
fi

if [[ -z "$PROMPT" ]]; then
  echo "Error: プロンプトが空です" >&2
  exit 1
fi

CODEX_PANE=$(get_running_pane)

if [[ -z "$CODEX_PANE" ]]; then
  echo "Error: codexペインが起動していません" >&2
  echo "まず起動してください: /second-opinion start" >&2
  exit 1
fi

# プロンプト送信
send_prompt_to_pane "$CODEX_PANE" "$PROMPT"

echo "プロンプトを送信しました。codexペインを確認してください。"
