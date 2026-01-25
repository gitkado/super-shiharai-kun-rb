#!/bin/bash
# second-opinion review - git diffレビュー

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# gitリポジトリかどうかを確認
if ! git rev-parse --git-dir &>/dev/null; then
  echo "Error: gitリポジトリではありません" >&2
  echo "git initまたはgit cloneでリポジトリを初期化してください" >&2
  exit 1
fi

# git diffを取得
# 優先順位: HEAD差分 → ステージング済み → ワーキングツリー
# NOTE: コミットがないリポジトリでは git diff HEAD が失敗するため、
#       最終的に git diff（unstaged changes）へフォールバック
DIFF=""
DIFF_ERROR=""

# 1. HEADとの差分（コミット済み + ステージング + ワーキングツリー）
if ! DIFF=$(git diff HEAD 2>&1); then
  DIFF_ERROR="$DIFF"
  DIFF=""
fi

# 2. ステージング済みの変更のみ
if [[ -z "$DIFF" ]]; then
  if ! DIFF=$(git diff --staged 2>&1); then
    DIFF_ERROR="$DIFF"
    DIFF=""
  fi
fi

# 3. ワーキングツリーの変更（unstaged changes）
if [[ -z "$DIFF" ]]; then
  if ! DIFF=$(git diff 2>&1); then
    DIFF_ERROR="$DIFF"
    DIFF=""
  fi
fi

if [[ -z "$DIFF" ]]; then
  if [[ -n "$DIFF_ERROR" ]]; then
    echo "Error: git diffの実行に失敗しました" >&2
    echo "詳細: $DIFF_ERROR" >&2
    exit 1
  fi
  echo "レビュー対象の変更がありません（git diffが空です）"
  echo ""
  echo "ヒント:"
  echo "  - 変更をステージング: git add <file>"
  echo "  - 特定のコミットとの差分: git diff <commit> で手動確認"
  exit 1
fi

# レビュープロンプトを構築
REVIEW_PROMPT="以下のgit diffをレビューしてください。問題点、改善提案、セキュリティ上の懸念があれば指摘してください。

$DIFF"

# ペインが起動中の場合はそこに送信
CODEX_PANE=$(get_running_pane)
if [[ -n "$CODEX_PANE" ]]; then
  # tmux buffer 経由で長文プロンプトを送信
  send_long_prompt_to_pane "$CODEX_PANE" "$REVIEW_PROMPT"
  echo "レビュー依頼を送信しました。codexペインを確認してください。"
  exit 0
fi

# ペインがない場合はワンショット実行
echo "codexペインが起動していないため、ワンショット実行します..."

CODEX_CMD=$(get_codex_command) || exit 1

OUTPUT_FILE=$(create_temp_file "so-review-output")
setup_cleanup_trap "$OUTPUT_FILE"

if ! $CODEX_CMD exec $CODEX_EXEC_ARGS --output-last-message "$OUTPUT_FILE" "$REVIEW_PROMPT"; then
  echo "Error: codex の実行に失敗しました" >&2
  exit 1
fi

if [[ -f "$OUTPUT_FILE" ]] && [[ -s "$OUTPUT_FILE" ]]; then
  cat "$OUTPUT_FILE"
else
  echo "Error: 出力ファイルが生成されませんでした" >&2
  exit 1
fi
