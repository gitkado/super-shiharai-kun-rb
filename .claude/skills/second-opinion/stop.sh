#!/bin/bash
# second-opinion stop - codexペインを終了

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

CODEX_PANE=$(get_running_pane)

if [[ -z "$CODEX_PANE" ]]; then
  echo "codexペインが見つかりません"
  exit 1
fi

# Ctrl+C で codex を終了
tmux send-keys -t "$CODEX_PANE" C-c
sleep 1

# ペインを閉じる
tmux kill-pane -t "$CODEX_PANE" 2>/dev/null || true
rm -f "$CODEX_PANE_FILE"

echo "codexペインを終了しました"
