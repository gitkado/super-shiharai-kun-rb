#!/bin/bash
# second-opinion 共通ライブラリ
# 各スクリプトから source して使用

# 厳格モード（呼び出し元で設定されていない場合に備え）
set -euo pipefail

# --------------------------------------------------------------------------
# 定数
# --------------------------------------------------------------------------

# プラットフォーム互換のMD5ハッシュ関数
_hash_string() {
  local input="$1"
  if command -v md5sum &>/dev/null; then
    echo -n "$input" | md5sum | cut -c1-8
  else
    echo -n "$input" | md5 | cut -c1-8
  fi
}

# プロジェクト固有のtmux user optionキーを生成
_get_tmux_option_key() {
  local project_hash
  # $(pwd -P) を使用してシンボリックリンクを解決した実パスを取得
  project_hash=$(_hash_string "$(pwd -P)")
  echo "@second_opinion_pane_${project_hash}"
}

# tmux user optionキー（セッション共有）
CODEX_PANE_OPTION="$(_get_tmux_option_key)"

# 後方互換のためファイルパスも保持（フォールバック用）
_get_pane_file() {
  local project_hash
  # $(pwd -P) を使用してシンボリックリンクを解決した実パスを取得
  project_hash=$(_hash_string "$(pwd -P)")
  # $TMPDIR を使用（未設定の場合は /tmp にフォールバック）
  local tmp_base="${TMPDIR:-/tmp}"
  # 末尾のスラッシュを除去
  tmp_base="${tmp_base%/}"
  echo "${tmp_base}/second-opinion-pane-${project_hash}"
}

CODEX_PANE_FILE="$(_get_pane_file)"

# codex モデル設定
# 環境変数 CODEX_MODEL で指定可能（未指定時は config.toml のデフォルトを使用）
# 例: CODEX_MODEL="o3" /second-opinion start
CODEX_MODEL="${CODEX_MODEL:-}"

# モデル引数を生成（モデルが指定されていれば -m オプションを追加）
_get_model_args() {
  if [[ -n "$CODEX_MODEL" ]]; then
    echo "-m $CODEX_MODEL"
  fi
}

# codex 引数設定
# 対話モード用（start.sh）: sandbox + 承認プロンプトスキップ
CODEX_INTERACTIVE_ARGS="--sandbox read-only -a never $(_get_model_args)"
# 非対話モード用（exec.sh, design.sh, review.sh）: sandbox + 承認プロンプトスキップ
# NOTE: codex exec には -a オプションがないため、-c で設定をオーバーライド
CODEX_EXEC_ARGS="--sandbox read-only -c approval_policy=\"never\" $(_get_model_args)"
# セッション継続用（ask.sh）: codex exec resume は --sandbox をサポートしないため -c で設定
CODEX_RESUME_ARGS="-c approval_policy=\"never\" $(_get_model_args)"

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
# tmux user optionを優先し、ファイルをフォールバックとして使用
get_running_pane() {
  local pane_id=""

  # 1. tmux user optionから取得（推奨）
  pane_id=$(tmux show-option -gqv "$CODEX_PANE_OPTION" 2>/dev/null || true)

  # 2. フォールバック: ファイルから取得（後方互換）
  if [[ -z "$pane_id" ]] && [[ -f "$CODEX_PANE_FILE" ]]; then
    pane_id=$(cat "$CODEX_PANE_FILE")
    # ファイルから取得した場合、tmux optionに移行
    if [[ -n "$pane_id" ]] && pane_exists "$pane_id"; then
      tmux set-option -gq "$CODEX_PANE_OPTION" "$pane_id"
      rm -f "$CODEX_PANE_FILE"
    fi
  fi

  if [[ -n "$pane_id" ]] && pane_exists "$pane_id"; then
    echo "$pane_id"
  else
    # 古いoption/ファイルをクリーンアップ
    tmux set-option -gqu "$CODEX_PANE_OPTION" 2>/dev/null || true
    rm -f "$CODEX_PANE_FILE"
  fi
}

# ペインIDを安全に保存（tmux user option + ファイル両方）
save_pane_id() {
  local pane_id="$1"
  # tmux user optionに保存（セッション共有）
  tmux set-option -gq "$CODEX_PANE_OPTION" "$pane_id"
  # 後方互換のためファイルにも保存
  echo "$pane_id" > "$CODEX_PANE_FILE"
  chmod 600 "$CODEX_PANE_FILE"
}

# ペインIDをクリア
clear_pane_id() {
  tmux set-option -gqu "$CODEX_PANE_OPTION" 2>/dev/null || true
  rm -f "$CODEX_PANE_FILE"
}

# 古いペイン状態をクリーンアップ
repair_pane_state() {
  local pane_id
  pane_id=$(get_running_pane)

  if [[ -n "$pane_id" ]]; then
    echo "ペインは正常に動作中です: $pane_id"
    return 0
  fi

  # 孤立した状態をクリーンアップ
  local option_value
  option_value=$(tmux show-option -gqv "$CODEX_PANE_OPTION" 2>/dev/null || true)

  if [[ -n "$option_value" ]] || [[ -f "$CODEX_PANE_FILE" ]]; then
    clear_pane_id
    echo "古いペイン状態をクリーンアップしました"
  else
    echo "クリーンアップ対象の状態はありません"
  fi
}

# --------------------------------------------------------------------------
# 一時ファイル管理（セキュアな方法）
# --------------------------------------------------------------------------

# セキュアな一時ファイルを作成し、パスを返す
create_temp_file() {
  local prefix="${1:-second-opinion}"
  # $TMPDIR を使用（未設定の場合は /tmp にフォールバック）
  local tmp_base="${TMPDIR:-/tmp}"
  # 末尾のスラッシュを除去
  tmp_base="${tmp_base%/}"
  # umask を設定して他ユーザーからのアクセスを防止
  (umask 077 && mktemp "${tmp_base}/${prefix}-XXXXXX")
}

# 一時ファイルをクリーンアップするtrapを設定
# 使用例: setup_cleanup_trap "$TEMP_FILE"
# 複数回呼び出し可能（ファイルは追記される）
setup_cleanup_trap() {
  # グローバル変数として保持（追記モード）
  if [[ -z "${_CLEANUP_FILES_INITIALIZED:-}" ]]; then
    _CLEANUP_FILES=()
    _CLEANUP_FILES_INITIALIZED=1
  fi
  _CLEANUP_FILES+=("$@")

  # EXIT + シグナルハンドリング
  _cleanup_handler() {
    rm -f "${_CLEANUP_FILES[@]}" 2>/dev/null || true
  }
  trap '_cleanup_handler' EXIT
  trap '_cleanup_handler; exit 130' INT
  trap '_cleanup_handler; exit 143' TERM
}

# --------------------------------------------------------------------------
# プロンプト送信（tmux load-buffer + paste-buffer 方式）
# --------------------------------------------------------------------------

# ペインにプロンプトを送信（自動で最適な方法を選択）
send_prompt_to_pane() {
  local pane_id="$1"
  local prompt="$2"

  # 長いプロンプト（500文字以上）または改行を含む場合はバッファ経由
  if [[ ${#prompt} -ge 500 ]] || [[ "$prompt" == *$'\n'* ]]; then
    send_long_prompt_to_pane "$pane_id" "$prompt"
    return $?
  fi

  # 短いプロンプトはリテラル送信
  tmux send-keys -t "$pane_id" -l "$prompt"

  # tmuxの処理完了を待機してからEnterを送信
  sleep 0.1
  tmux send-keys -t "$pane_id" Enter
}

# ペインに長いプロンプトを送信（バッファ経由）
send_long_prompt_to_pane() {
  local pane_id="$1"
  local prompt="$2"

  # 一時ファイル経由でバッファにロード
  local temp_file
  temp_file=$(create_temp_file "so-buffer")

  # バッファ名をPIDでユニーク化（並行実行対策）
  local buffer_name="so-prompt-$$"

  # ローカルクリーンアップ関数
  _local_cleanup() {
    rm -f "$temp_file" 2>/dev/null || true
    tmux delete-buffer -b "$buffer_name" 2>/dev/null || true
  }

  # 関数終了時に必ずクリーンアップ
  trap '_local_cleanup' RETURN

  echo "$prompt" > "$temp_file"

  # tmuxバッファにロードしてペースト
  if ! tmux load-buffer -b "$buffer_name" "$temp_file"; then
    return 1
  fi
  tmux paste-buffer -b "$buffer_name" -t "$pane_id"

  # ペースト完了を待機してからEnterを送信
  # プロンプトの長さに応じて待機時間を調整（最小0.1秒、最大1.0秒）
  local prompt_len=${#prompt}
  local wait_time
  wait_time=$(awk -v len="$prompt_len" 'BEGIN {
    t = len / 5000 + 0.1
    if (t > 1.0) t = 1.0
    printf "%.2f", t
  }')
  sleep "$wait_time"

  tmux send-keys -t "$pane_id" Enter
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

# --------------------------------------------------------------------------
# セッションID管理（codex exec resume 用）
# --------------------------------------------------------------------------

# セッションID用のtmux user optionキーを生成
_get_session_option_key() {
  local project_hash
  project_hash=$(_hash_string "$(pwd -P)")
  echo "@second_opinion_session_${project_hash}"
}

# セッションIDを保存
save_session_id() {
  local session_id="$1"
  local option_key
  option_key=$(_get_session_option_key)
  tmux set-option -gq "$option_key" "$session_id"
}

# セッションIDを取得
get_session_id() {
  local option_key
  option_key=$(_get_session_option_key)
  tmux show-option -gqv "$option_key" 2>/dev/null || true
}

# セッションIDをクリア
clear_session_id() {
  local option_key
  option_key=$(_get_session_option_key)
  tmux set-option -gqu "$option_key" 2>/dev/null || true
}

# --------------------------------------------------------------------------
# JSONL出力からの応答抽出
# --------------------------------------------------------------------------

# jq がインストールされているか確認
check_jq_installed() {
  if ! command -v jq &>/dev/null; then
    echo "Error: jq がインストールされていません" >&2
    echo "インストール: brew install jq" >&2
    return 1
  fi
}

# JSONL出力から最新のagent_messageを抽出
extract_last_agent_message() {
  local jsonl_file="$1"

  jq -rs '[.[] | select(.type == "item.completed") | .item | select(.type == "agent_message")] | last | .text // empty' "$jsonl_file"
}

# JSONL出力からセッションIDを抽出
extract_session_id() {
  local jsonl_file="$1"
  jq -rs '[.[] | select(.type == "thread.started")] | first | .thread_id // empty' "$jsonl_file"
}

# --------------------------------------------------------------------------
# 出力キャプチャ
# --------------------------------------------------------------------------

# ペインの出力をキャプチャ（codexの応答完了を検知）
# 使用例: capture_pane_output "$pane_id" 60
#         capture_pane_output "$pane_id" 60 -500  # 500行取得
capture_pane_output() {
  local pane_id="$1"
  local timeout="${2:-60}"  # デフォルト60秒
  local capture_lines="${3:--300}"  # デフォルト300行（100行では長い応答が切り捨てられる）

  # 送信直後は処理中の可能性があるため少し待つ
  sleep 2

  local prev_output=""
  local stable_count=0

  for i in $(seq 1 "$timeout"); do
    sleep 1
    local output
    output=$(tmux capture-pane -t "$pane_id" -p -S "$capture_lines")

    # 「Working」状態でないことを確認
    if ! echo "$output" | grep -q 'Working'; then
      # 前回と同じ出力が2回続いたら完了とみなす
      if [[ "$output" == "$prev_output" ]]; then
        stable_count=$((stable_count + 1))
        if [[ $stable_count -ge 2 ]]; then
          echo "$output"
          return 0
        fi
      else
        stable_count=0
      fi
    fi
    prev_output="$output"
  done

  echo "Warning: タイムアウト（${timeout}秒）" >&2
  tmux capture-pane -t "$pane_id" -p -S "$capture_lines"
  return 1
}
