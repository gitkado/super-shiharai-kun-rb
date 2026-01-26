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

# feature を特定し、コンテキストを取得
FEATURE=$(get_current_feature)
FEATURE_CONTEXT=""
if [[ -n "$FEATURE" ]]; then
  FEATURE_CONTEXT=$(get_feature_context "$FEATURE")
fi

# レビュープロンプトを構築
REVIEW_PROMPT="以下のgit diffをレビューしてください。"

# コンテキストがあれば追加
if [[ -n "$FEATURE" ]]; then
  REVIEW_PROMPT+="

## コンテキスト
Feature: $FEATURE"
  if [[ -n "$FEATURE_CONTEXT" ]]; then
    REVIEW_PROMPT+="
$FEATURE_CONTEXT"
  fi
fi

REVIEW_PROMPT+="

## git diff
\`\`\`diff
$DIFF
\`\`\`

## レビュー観点
1. 要件との整合性（コンテキストがある場合）
2. 設計方針との一貫性
3. セキュリティ上の懸念
4. パフォーマンス影響
5. テストカバレッジ
6. コードの可読性・保守性

## 出力形式（必須）
各指摘に重要度を付与してください:
- [BLOCKER]: マージ不可。セキュリティ脆弱性、データ破損、本番障害リスク
- [WARNING]: 要検討。設計違反、パフォーマンス懸念、保守性低下
- [INFO]: 参考情報。コードスタイル、改善提案、ベストプラクティス

重要度ごとにセクション分けして出力してください。"

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
