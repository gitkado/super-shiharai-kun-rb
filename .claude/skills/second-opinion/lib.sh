#!/bin/bash
# second-opinion 共通ライブラリ
# 各スクリプトから source して使用

# 厳格モード（呼び出し元で設定されていない場合に備え）
set -euo pipefail

# --------------------------------------------------------------------------
# 定数
# --------------------------------------------------------------------------

# セッション名を含むユニークなペインファイルパスを生成
_get_pane_file() {
  local session_name="${TMUX_PANE:-}"
  local project_hash
  project_hash=$(echo "$PWD" | md5 | cut -c1-8)

  if [[ -n "$session_name" ]]; then
    local session_hash
    session_hash=$(echo "$session_name" | md5 | cut -c1-4)
    echo "/tmp/second-opinion-pane-${project_hash}-${session_hash}"
  else
    echo "/tmp/second-opinion-pane-${project_hash}"
  fi
}

CODEX_PANE_FILE="$(_get_pane_file)"

# codex 共通引数: sandbox + 承認プロンプトスキップ
CODEX_COMMON_ARGS="--sandbox read-only -a never"

# --------------------------------------------------------------------------
# 前提条件チェック
# --------------------------------------------------------------------------

check_tmux_installed() {
  if ! command -v tmux &>/dev/null; then
    echo "Error: tmux がインストールされていません" >&2
    echo "インストール: brew install tmux" >&2
    return 1
  fi
}

check_tmux_session() {
  if [[ -z "${TMUX:-}" ]]; then
    echo "Error: tmuxセッション外で実行されています" >&2
    echo "まず tmux を起動してください: tmux new -s dev" >&2
    return 1
  fi
}

# --------------------------------------------------------------------------
# codex コマンド検出
# --------------------------------------------------------------------------

get_codex_command() {
  if command -v codex &>/dev/null; then
    echo "codex"
  elif command -v npx &>/dev/null; then
    echo "npx codex"
  else
    echo "Error: codex が見つかりません" >&2
    echo "インストール方法:" >&2
    echo "  npm install -g @openai/codex" >&2
    echo "または npx codex で実行してください" >&2
    return 1
  fi
}

# --------------------------------------------------------------------------
# ペイン管理
# --------------------------------------------------------------------------

# ペインが存在するか確認
pane_exists() {
  local pane_id="${1:-}"
  [[ -n "$pane_id" ]] && tmux list-panes -a -F "#{pane_id}" 2>/dev/null | grep -q "^$pane_id$"
}

# 起動中のペインIDを取得（存在しなければ空文字）
get_running_pane() {
  if [[ ! -f "$CODEX_PANE_FILE" ]]; then
    return 0
  fi

  local pane_id
  pane_id=$(cat "$CODEX_PANE_FILE")

  if pane_exists "$pane_id"; then
    echo "$pane_id"
  else
    # 古いファイルを削除
    rm -f "$CODEX_PANE_FILE"
  fi
}

# ペインIDを安全に保存（0600パーミッション）
save_pane_id() {
  local pane_id="$1"
  echo "$pane_id" > "$CODEX_PANE_FILE"
  chmod 600 "$CODEX_PANE_FILE"
}

# 古いペインファイルをクリーンアップ
repair_pane_state() {
  if [[ -f "$CODEX_PANE_FILE" ]]; then
    local pane_id
    pane_id=$(cat "$CODEX_PANE_FILE")
    if ! pane_exists "$pane_id"; then
      rm -f "$CODEX_PANE_FILE"
      echo "古いペインファイルを削除しました: $CODEX_PANE_FILE"
      return 0
    fi
    echo "ペインは正常に動作中です: $pane_id"
  else
    echo "クリーンアップ対象のペインファイルはありません"
  fi
}

# --------------------------------------------------------------------------
# 一時ファイル管理（セキュアな方法）
# --------------------------------------------------------------------------

# セキュアな一時ファイルを作成し、パスを返す
create_temp_file() {
  local prefix="${1:-second-opinion}"
  mktemp "/tmp/${prefix}-XXXXXX"
}

# 一時ファイルをクリーンアップするtrapを設定
# 使用例: setup_cleanup_trap "$TEMP_FILE"
setup_cleanup_trap() {
  # グローバル変数として保持（trapから参照するため）
  _CLEANUP_FILES=("$@")
  trap 'rm -f "${_CLEANUP_FILES[@]}" 2>/dev/null || true' EXIT
}

# --------------------------------------------------------------------------
# プロンプト送信（tmux load-buffer + paste-buffer 方式）
# --------------------------------------------------------------------------

# ペインにプロンプトを送信（短いテキスト用）
send_prompt_to_pane() {
  local pane_id="$1"
  local prompt="$2"

  # リテラル送信
  tmux send-keys -t "$pane_id" -l "$prompt"
  tmux send-keys -t "$pane_id" Enter
}

# ペインに長いプロンプトを送信（バッファ経由）
send_long_prompt_to_pane() {
  local pane_id="$1"
  local prompt="$2"

  # 一時ファイル経由でバッファにロード
  local temp_file
  temp_file=$(create_temp_file "so-buffer")
  echo "$prompt" > "$temp_file"

  # tmuxバッファにロードしてペースト
  tmux load-buffer -b so-prompt "$temp_file"
  tmux paste-buffer -b so-prompt -t "$pane_id"
  tmux send-keys -t "$pane_id" Enter

  # クリーンアップ
  rm -f "$temp_file"
  tmux delete-buffer -b so-prompt 2>/dev/null || true
}

# --------------------------------------------------------------------------
# 入力バリデーション
# --------------------------------------------------------------------------

# トピック名をサニタイズ（パストラバーサル防止）
sanitize_topic() {
  local topic="$1"

  # 空チェック
  if [[ -z "$topic" ]]; then
    echo "Error: トピック名が空です" >&2
    return 1
  fi

  # 許可文字のみ（英数字、ハイフン、アンダースコア）
  if [[ ! "$topic" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: トピック名に使用できない文字が含まれています" >&2
    echo "使用可能: 英数字、ハイフン、アンダースコア" >&2
    return 1
  fi

  # パストラバーサルチェック（念のため）
  if [[ "$topic" == *".."* ]]; then
    echo "Error: 不正なトピック名です" >&2
    return 1
  fi

  echo "$topic"
}

# パスの安全性チェック（シンボリックリンク拒否）
validate_safe_path() {
  local path="$1"

  if [[ ! -e "$path" ]]; then
    return 0  # 存在しないパスはOK（後続で処理）
  fi

  # シンボリックリンクを拒否
  if [[ -L "$path" ]]; then
    echo "Error: シンボリックリンクは許可されていません: $path" >&2
    return 1
  fi

  return 0
}
