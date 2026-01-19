#!/bin/bash
# second-opinion start - codexペインを起動

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# 前提条件チェック
check_tmux_installed || exit 1
check_tmux_session || exit 1

CODEX_CMD=$(get_codex_command) || exit 1

# 既存ペインの確認
EXISTING_PANE=$(get_running_pane)
if [[ -n "$EXISTING_PANE" ]]; then
  echo "既にcodexペインが存在します: $EXISTING_PANE"
  echo "停止するには: /second-opinion stop"
  exit 0
fi

# 新規ペイン作成（右側40%）
CODEX_PANE=$(tmux split-window -h -p 40 -P -F "#{pane_id}" -c "$PWD")
save_pane_id "$CODEX_PANE"

# codex起動
tmux send-keys -t "$CODEX_PANE" "$CODEX_CMD $CODEX_COMMON_ARGS" Enter

# 起動確認（少し待って確認）
sleep 2
if pane_exists "$CODEX_PANE"; then
  echo "codexペインを起動しました: $CODEX_PANE"
else
  echo "Error: codexペインの起動に失敗しました" >&2
  rm -f "$CODEX_PANE_FILE"
  exit 1
fi
