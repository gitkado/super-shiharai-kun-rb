#!/bin/bash
# second-opinion ask - codexセッションにプロンプト送信・応答取得
# codex exec resume <session_id> --json でセッションを継続し、jqで応答を抽出

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
  echo "  --help, -h    このヘルプを表示"
  echo ""
  echo "例:"
  echo "  /second-opinion ask このコードをレビューして"
  echo "  /second-opinion ask 複雑な設計相談..."
  echo "  echo 'プロンプト' | /second-opinion ask  # stdin から読み込み"
  echo ""
  echo "注意: まず /second-opinion start でセッションを開始してください"
  exit 0
fi

# 前提条件チェック
check_tmux_installed || exit 1
check_tmux_session || exit 1
check_jq_installed || exit 1

CODEX_CMD=$(get_codex_command) || exit 1

# セッションIDを取得
SESSION_ID=$(get_session_id)
if [[ -z "$SESSION_ID" ]]; then
  echo "Error: codexセッションが開始されていません" >&2
  echo "まず起動してください: /second-opinion start" >&2
  exit 1
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

# 一時ファイル作成
OUTPUT_FILE=$(create_temp_file "so-ask-jsonl")
setup_cleanup_trap "$OUTPUT_FILE"

echo "codexに質問を送信中..." >&2

# codex exec resume でセッション継続
# NOTE: シェル変数展開を正しく行うためevalを使用、プロンプトはシングルクォートでエスケープ
# NOTE: codex exec resume は --sandbox をサポートしないため CODEX_RESUME_ARGS を使用
ESCAPED_PROMPT=$(printf '%s' "$PROMPT" | sed "s/'/'\\\\''/g")
if ! eval "$CODEX_CMD exec resume '$SESSION_ID' $CODEX_RESUME_ARGS --json '$ESCAPED_PROMPT'" > "$OUTPUT_FILE" 2>&1; then
  echo "Error: codex の実行に失敗しました" >&2
  echo "--- 詳細 ---" >&2
  cat "$OUTPUT_FILE" >&2
  exit 1
fi

# 最新応答を抽出
RESPONSE=$(extract_last_agent_message "$OUTPUT_FILE")
if [[ -n "$RESPONSE" ]]; then
  echo "$RESPONSE"
else
  echo "Error: 応答を取得できませんでした" >&2
  echo "--- JSONL出力 ---" >&2
  cat "$OUTPUT_FILE" >&2
  exit 1
fi
