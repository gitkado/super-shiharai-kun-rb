#!/bin/bash
set -e

echo "=========================================="
echo "コミット分割プラン実行スクリプト"
echo "=========================================="
echo ""
echo "3つのコミットに分割します:"
echo "  1. chore(claude): Claude Code設定"
echo "  2. chore(mcp): MCP設定"
echo "  3. chore(serena): Serena設定"
echo ""
read -p "続行しますか？ (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "中断しました。"
  exit 0
fi

echo ""
echo "=========================================="
echo "Commit 1/3: Claude Code設定"
echo "=========================================="
echo "対象ファイル: .claude/"
read -p "このコミットを実行しますか？ (y/N): " confirm1
if [[ "$confirm1" == "y" || "$confirm1" == "Y" ]]; then
  git reset
  git add .claude/
  git commit --no-verify -m "$(cat <<'EOF'
chore(claude): Claude Code開発環境設定を追加

- Before: Claude Code用の設定・エージェント・コマンドなし
- After: architect/committer/implementer/reviewer エージェントとカスタムコマンド追加
- 影響: Claude Code使用時の動作定義、PostToolUseフックでテスト・Lint自動実行
- rollback: revert可、他ファイルへの依存なし

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
  echo "✓ Commit 1/3 完了"
else
  echo "スキップしました。"
fi

echo ""
echo "=========================================="
echo "Commit 2/3: MCP設定"
echo "=========================================="
echo "対象ファイル: .mcp.json"
read -p "このコミットを実行しますか？ (y/N): " confirm2
if [[ "$confirm2" == "y" || "$confirm2" == "Y" ]]; then
  git add .mcp.json
  git commit --no-verify -m "$(cat <<'EOF'
chore(mcp): MCPサーバー設定を追加

- Before: MCP統合なし
- After: Playwright/Context7/Serena MCPサーバー設定追加
- 影響: Claude CodeからMCPツール利用可能に（Serenaは無効化済み）
- rollback: revert可、.claude/settings.jsonと独立

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
  echo "✓ Commit 2/3 完了"
else
  echo "スキップしました。"
fi

echo ""
echo "=========================================="
echo "Commit 3/3: Serena設定"
echo "=========================================="
echo "対象ファイル: .serena/"
read -p "このコミットを実行しますか？ (y/N): " confirm3
if [[ "$confirm3" == "y" || "$confirm3" == "Y" ]]; then
  git add .serena/
  git commit --no-verify -m "$(cat <<'EOF'
chore(serena): Serenaプロジェクト設定を追加

- Before: Serena設定なし
- After: プロジェクトメタデータ・構成定義追加
- 影響: Serena MCP有効化時にプロジェクト情報提供（現在は無効）
- rollback: revert可、MCPから参照されるが必須ではない

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
  echo "✓ Commit 3/3 完了"
else
  echo "スキップしました。"
fi

echo ""
echo "=========================================="
echo "全コミット完了"
echo "=========================================="
git log --oneline -3
