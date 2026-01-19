#!/bin/bash
# second-opinion status - ペイン状態を確認

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# --repair オプションの処理
if [[ "${1:-}" == "--repair" ]]; then
  repair_pane_state
  exit 0
fi

# --help オプション
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "使用方法: /second-opinion status [OPTIONS]"
  echo ""
  echo "オプション:"
  echo "  --repair    古いペインファイルをクリーンアップ"
  echo "  --help, -h  このヘルプを表示"
  exit 0
fi

CODEX_PANE=$(get_running_pane)

if [[ -z "$CODEX_PANE" ]]; then
  echo "Status: NOT RUNNING"
  echo ""
  echo "起動するには: /second-opinion start"
  exit 0
fi

echo "Status: RUNNING"
echo "Pane ID: $CODEX_PANE"
echo ""
echo "設定:"
echo "  Sandbox: read-only"
echo "  Approval: never (自動承認)"
echo "  Args: $CODEX_COMMON_ARGS"
echo ""
echo "使用可能なコマンド:"
echo "  /second-opinion ask <prompt>   - プロンプト送信"
echo "  /second-opinion exec <prompt>  - ワンショット実行"
echo "  /second-opinion review         - git diffレビュー"
echo "  /second-opinion design <topic> - 設計相談"
echo "  /second-opinion stop           - 終了"
echo ""
echo "トラブルシューティング:"
echo "  /second-opinion status --repair - 古いペインファイルをクリーンアップ"
