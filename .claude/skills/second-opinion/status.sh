#!/bin/bash
# second-opinion status - セッション状態を確認

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# --repair オプションの処理
if [[ "${1:-}" == "--repair" ]]; then
  repair_pane_state
  # セッションIDもクリア
  clear_session_id 2>/dev/null || true
  echo "セッションIDもクリアしました"
  exit 0
fi

# --help オプション
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "使用方法: /second-opinion status [OPTIONS]"
  echo ""
  echo "オプション:"
  echo "  --repair    古い状態をクリーンアップ"
  echo "  --help, -h  このヘルプを表示"
  exit 0
fi

# セッションID確認
SESSION_ID=$(get_session_id)

# 旧方式のペインも確認（後方互換）
CODEX_PANE=$(get_running_pane)

if [[ -z "$SESSION_ID" ]] && [[ -z "$CODEX_PANE" ]]; then
  echo "Status: NOT RUNNING"
  echo ""
  echo "起動するには: /second-opinion start"
  exit 0
fi

echo "Status: RUNNING"

# セッションID
if [[ -n "$SESSION_ID" ]]; then
  echo "Session ID: $SESSION_ID"
fi

# 監視ペイン
if [[ -n "$CODEX_PANE" ]]; then
  echo "Watch Pane: $CODEX_PANE"
fi

echo ""
echo "設定:"
echo "  Sandbox: read-only"
echo "  Approval: never (自動承認)"
echo "  Args: $CODEX_EXEC_ARGS"
echo ""
echo "使用可能なコマンド:"
echo "  /second-opinion ask <prompt>   - プロンプト送信（セッション継続）"
echo "  /second-opinion exec <prompt>  - ワンショット実行"
echo "  /second-opinion review         - git diffレビュー"
echo "  /second-opinion design <topic> - 設計相談"
echo "  /second-opinion stop           - セッション終了"
echo ""
echo "トラブルシューティング:"
echo "  /second-opinion status --repair - 古い状態をクリーンアップ"
