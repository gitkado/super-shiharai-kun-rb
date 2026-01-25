#!/bin/bash
# second-opinion stop - codexセッションを終了

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# セッションIDを確認
SESSION_ID=$(get_session_id)

if [[ -z "$SESSION_ID" ]]; then
  echo "codexセッションが見つかりません"
  exit 1
fi

# セッションIDをクリア
clear_session_id
echo "codexセッションを終了しました"
echo "Session ID: $SESSION_ID"
