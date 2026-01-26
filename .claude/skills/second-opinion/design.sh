#!/bin/bash
# second-opinion design - 設計相談

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TOPIC="${1:-}"

if [[ -z "$TOPIC" ]]; then
  echo "Error: トピックを指定してください" >&2
  echo "使用方法: /second-opinion design <topic>" >&2
  exit 1
fi

# トピック名のサニタイズ（パストラバーサル防止）
TOPIC=$(sanitize_topic "$TOPIC") || exit 1

# 関連する設計ドキュメントを探す
DESIGN_DOC=""
SPECS_DIR="ai/specs/$TOPIC"

# シンボリックリンクチェック
validate_safe_path "$SPECS_DIR" || exit 1

if [[ -d "$SPECS_DIR" ]]; then
  # 各ファイルにヘッダーを付けて連結
  for doc_file in "$SPECS_DIR"/*.md; do
    if [[ -f "$doc_file" ]]; then
      # 各ファイルもシンボリックリンクチェック
      validate_safe_path "$doc_file" || continue
      filename=$(basename "$doc_file")
      # ファイル読み込みエラーのハンドリング
      file_content=$(head -100 "$doc_file" 2>/dev/null) || {
        echo "Warning: ファイルの読み込みに失敗しました: $doc_file" >&2
        continue
      }
      DESIGN_DOC+="
--- $filename ---
$file_content
"
    fi
  done
fi

# 設計相談プロンプト
DESIGN_PROMPT="設計についてセカンドオピニオンをお願いします。

トピック: $TOPIC"

if [[ -n "$DESIGN_DOC" ]]; then
  DESIGN_PROMPT="$DESIGN_PROMPT

関連する設計ドキュメント:
$DESIGN_DOC"
fi

DESIGN_PROMPT="$DESIGN_PROMPT

この設計について、以下の観点からレビューしてください：
1. アーキテクチャ上の問題点
2. 拡張性・保守性の観点
3. より良いアプローチの提案
4. 見落としている考慮事項
5. セキュリティ上のリスク

## 出力形式（必須）
各指摘に重要度を付与してください:
- [BLOCKER]: 設計の根本的な問題。このまま進めると重大な技術的負債やセキュリティリスクが発生
- [WARNING]: 要検討。より良いアプローチがある、または潜在的な問題がある
- [INFO]: 参考情報。改善提案、ベストプラクティス、代替案

重要度ごとにセクション分けして出力してください。"

# ペインが起動中の場合はそこに送信
CODEX_PANE=$(get_running_pane)
if [[ -n "$CODEX_PANE" ]]; then
  send_long_prompt_to_pane "$CODEX_PANE" "$DESIGN_PROMPT"
  echo "設計相談を送信しました。codexペインを確認してください。"
  exit 0
fi

# ペインがない場合はワンショット実行
echo "codexペインが起動していないため、ワンショット実行します..."

CODEX_CMD=$(get_codex_command) || exit 1

OUTPUT_FILE=$(create_temp_file "so-design-output")
setup_cleanup_trap "$OUTPUT_FILE"

if ! $CODEX_CMD exec $CODEX_EXEC_ARGS --output-last-message "$OUTPUT_FILE" "$DESIGN_PROMPT"; then
  echo "Error: codex の実行に失敗しました" >&2
  exit 1
fi

if [[ -f "$OUTPUT_FILE" ]] && [[ -s "$OUTPUT_FILE" ]]; then
  cat "$OUTPUT_FILE"
else
  echo "Error: 出力ファイルが生成されませんでした" >&2
  exit 1
fi
