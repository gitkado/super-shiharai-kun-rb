---
name: second-opinion
description: codex（OpenAI CLI）を呼び出してセカンドオピニオンを得る
---

あなたは Claude Code のセカンドオピニオン担当です。codex（OpenAI CLI）を使用して、第三者視点のレビューやアドバイスを取得します。

## 前提条件

このスキルを使用するには以下が必要です：

1. **tmux**: ターミナルマルチプレクサ
2. **codex**: OpenAI CLI（`npm install -g @openai/codex` または `npx codex`）
3. **jq**: JSONプロセッサ（`brew install jq`）
4. **tmuxセッション内で実行**: `$TMUX` 環境変数が設定されていること

## クイックスタート

### パターン1: 対話的使用（推奨）

セッションを起動して、複数の質問を連続で行う場合（コンテキスト維持）：

```bash
# 1. codexセッションを開始
.claude/skills/second-opinion/start.sh

# 2. 質問を送信（応答がstdoutに返る）
.claude/skills/second-opinion/ask.sh "このコードの設計について意見をください"

# 3. 追加の質問（前の会話のコンテキストを維持）
.claude/skills/second-opinion/ask.sh "パフォーマンス面で改善点はありますか"

# 4. セッション終了
.claude/skills/second-opinion/stop.sh
```

**注意**: `codex exec resume` を使用してセッションを継続します。応答は直接stdoutに出力されます。

### パターン2: ワンショット実行

単発の質問をすぐに解決したい場合：

```bash
# ペインなしで直接実行（結果がstdoutに返る）
.claude/skills/second-opinion/exec.sh "このエラーの原因を教えて"
```

### パターン3: git diffレビュー

コード変更のレビューを依頼する場合：

```bash
# 現在の変更をレビュー（ワンショット実行）
.claude/skills/second-opinion/review.sh
```

## 実行方法の注意

**重要**: 全てのスクリプトは直接実行してください。`bash` を先頭に付けると許可が求められます。

- 正しい: `.claude/skills/second-opinion/exec.sh "prompt"`
- 間違い: `bash .claude/skills/second-opinion/exec.sh "prompt"`

スクリプトは全て実行可能（`chmod +x`）です。

## コマンド一覧

| コマンド | 説明 | スクリプト |
|----------|------|-----------|
| `/second-opinion start` | codexセッションを開始 | `start.sh` |
| `/second-opinion stop` | codexセッションを終了 | `stop.sh` |
| `/second-opinion status` | セッション状態を確認 | `status.sh` |
| `/second-opinion ask <prompt>` | セッション継続でプロンプト送信 | `ask.sh` |
| `/second-opinion exec <prompt>` | ワンショット実行 | `exec.sh` |
| `/second-opinion review` | git diffレビュー | `review.sh` |
| `/second-opinion design <topic>` | 設計相談 | `design.sh` |

## コマンド詳細

### `/second-opinion start` - codexセッションを開始

`codex exec --json` で新規セッションを開始し、セッションIDを保存します。

**実行:** `.claude/skills/second-opinion/start.sh`

**動作:**

1. `codex exec --json` でセッションを開始
2. JSONL出力からセッションIDを抽出
3. tmux user optionにセッションIDを保存

### `/second-opinion stop` - codexセッションを終了

セッションIDをクリアして終了します。

**実行:** `.claude/skills/second-opinion/stop.sh`

### `/second-opinion status` - セッション状態を確認

codexセッションの状態とセッションIDを確認します。

**実行:** `.claude/skills/second-opinion/status.sh`

### `/second-opinion ask` - セッション継続でプロンプト送信

`codex exec resume <session_id> --json` でセッションを継続し、応答をJSONLから抽出してstdoutに出力します。

**実行:** `.claude/skills/second-opinion/ask.sh "<prompt>"`

**動作:**

1. 保存されたセッションIDを取得
2. `codex exec resume <session_id> --json` でプロンプト送信
3. JSONL出力から最新の `agent_message` を抽出
4. 応答テキストをstdoutに出力

**使用例:**

```bash
# 基本的な使用法
.claude/skills/second-opinion/ask.sh "このコードをレビューして"

# stdinからプロンプトを読み込み
echo "このコードの問題点は？" | .claude/skills/second-opinion/ask.sh
cat prompt.txt | .claude/skills/second-opinion/ask.sh

# コンテキスト維持の例
.claude/skills/second-opinion/ask.sh "1+1は？"       # → "2"
.claude/skills/second-opinion/ask.sh "さっきの答えに1を足して"  # → "3"（コンテキスト維持）
```

### `/second-opinion exec` - ワンショット実行

codexを一時的に起動してプロンプトを実行し、結果を取得します。結果は直接stdoutに出力されます。

**実行:** `.claude/skills/second-opinion/exec.sh "<prompt>"`

### `/second-opinion review` - git diffレビュー（鬼レビュー）

現在のgit diffをcodexに送ってコードレビューを依頼します（ワンショット実行）。

**実行:** `.claude/skills/second-opinion/review.sh`

**特徴:**

- **自動コンテキスト付与**: feature を自動特定し、`ai/specs/<feature>/` の要件・設計ドキュメントを添付
- **重要度付与**: 各指摘に BLOCKER / WARNING / INFO の重要度を付与
- **構造化出力**: Claude側が要否判断しやすい形式で出力

**feature 特定の優先順位:**

1. 環境変数 `FEATURE` が設定されている場合
2. `ai/board.md` の Current Work セクションに feature が記載されている場合
3. git diff のパスから `app/packages/<package>/` を抽出

### `/second-opinion design` - 設計相談

設計についてセカンドオピニオンを求めます（ワンショット実行）。`ai/specs/<topic>/` に設計ドキュメントがあれば参照します。

**実行:** `.claude/skills/second-opinion/design.sh "<topic>"`

## exec vs ask の使い分け

| 観点 | `exec` | `ask` |
|------|--------|-------|
| 用途 | 単発の質問 | 連続した対話 |
| セッション | 不要 | 必要（`start`で開始） |
| コンテキスト | 毎回リセット | セッション内で維持 |
| 結果取得 | stdout に直接出力 | stdout に直接出力 |
| 推奨ケース | 簡単な質問、CI/CD | 設計相談、深掘り |

## review / design の動作

`review` と `design` コマンドはワンショット実行されます：

- 一時的にcodexを起動
- 結果をstdoutに出力
- 終了後にcodexは停止

**ヒント**: セッション継続で使用したい場合は、出力を `ask` に渡してください。

## トラブルシューティング

### Q: 「codex が見つかりません」と表示される

**A:** codexがインストールされていません。以下のいずれかで対処：

```bash
# グローバルインストール（推奨）
npm install -g @openai/codex

# または npx 経由で実行（スクリプトが自動検出）
# 特別な設定は不要
```

### Q: 「tmuxセッション外で実行されています」と表示される

**A:** tmuxセッション内で実行する必要があります：

```bash
# 新しいtmuxセッションを開始
tmux new -s dev

# または既存のセッションにアタッチ
tmux attach -t dev
```

### Q: セッションが見つからない

**A:** セッション状態をリセットしてください：

```bash
# 状態確認
.claude/skills/second-opinion/status.sh

# 古い状態をクリーンアップ
.claude/skills/second-opinion/status.sh --repair

# 再起動
.claude/skills/second-opinion/start.sh
```

### Q: jq が見つからない

**A:** jqをインストールしてください：

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Q: git diffが取得できない

**A:** 以下を確認してください：

1. gitリポジトリ内で実行しているか
2. 変更がステージングされているか（`git status`で確認）
3. HEADコミットが存在するか（新規リポジトリの場合）

```bash
# 変更をステージング
git add <file>

# ステージング済みの差分をレビュー
.claude/skills/second-opinion/review.sh
```

## エラーハンドリング

| エラー | 検出方法 | 対処 |
|--------|----------|------|
| codex未インストール | `command -v codex` | `npx codex` を試行。それも失敗なら `npm install -g @openai/codex` を案内 |
| jq未インストール | `command -v jq` | `brew install jq` を案内 |
| tmux未インストール | `command -v tmux` | `brew install tmux` を案内 |
| tmuxセッション外 | `$TMUX` 変数が空 | `tmux new -s dev` でセッション開始を案内 |
| セッションID未設定 | `get_session_id` が空 | `start.sh` でセッション開始を案内 |

## 動作イメージ

`codex exec resume` を使用してセッションを継続します。

```text
+---------------------------------------------------------------+
|  Claude Code (Main)                                           |
|                                                               |
|  > /second-opinion start     → セッション開始（ID保存）       |
|  > /second-opinion ask "..." → 応答がstdoutに出力             |
|  > /second-opinion ask "..." → コンテキスト維持で継続         |
|  > /second-opinion stop      → セッションIDクリア             |
+---------------------------------------------------------------+
```

セッションIDはtmux user optionに保存され、同じtmuxセッション内であれば別のペインからもアクセス可能です。

## ディレクトリ構成

```text
.claude/skills/second-opinion/
├── SKILL.md      # このファイル（スキル定義）
├── lib.sh        # 共通ライブラリ（各スクリプトから source）
├── start.sh      # セッション開始
├── stop.sh       # セッション終了
├── status.sh     # セッション状態確認
├── ask.sh        # プロンプト送信
├── exec.sh       # ワンショット実行
├── review.sh     # git diffレビュー
└── design.sh     # 設計相談
```

## モデル設定

デフォルトは `~/.codex/config.toml` の設定を使用します（通常 **gpt-5.2-codex**）。

### 環境変数でモデル指定

```bash
# セッション開始時にモデルを指定
CODEX_MODEL="gpt-5.2-codex" .claude/skills/second-opinion/start.sh

# ワンショット実行でモデル指定
CODEX_MODEL="gpt-5.2-codex" .claude/skills/second-opinion/exec.sh "質問"
```

### 推論努力（Reasoning Effort）

タスクの複雑さに応じて推論努力を選択（`~/.codex/config.toml` で設定）：

| 設定 | 用途 | 特徴 |
|------|------|------|
| `medium` | 日常のコードレビュー、軽い質問 | バランス型、速度重視 |
| `high` | 設計相談、複雑なレビュー | 深い推論、品質重視 |

**デフォルト設定**: `medium`

※ 1トークンあたりの単価は同じだが、`high` は推論トークンが増えるため総コストが上がる傾向

### 料金目安

- 入力: $1.75 / 1Mトークン
- 出力: $14 / 1Mトークン
- キャッシュ入力: $0.175 / 1Mトークン

※ `high` は推論トークンが増えるため、同じタスクでも総コストが上がる傾向

## 注意事項

- codexは `--sandbox read-only` モードで起動（安全性のため）
- セッションIDはプロジェクトディレクトリごとに管理（tmux user option）
- 複数プロジェクトで同時に使用可能
- 応答抽出にjqを使用（JSONL形式からagent_messageを抽出）
- 同じtmuxセッション内であれば別ペインからも `stop` / `status` が可能

---

## 重要度レベル

`review` と `design` コマンドは、各指摘に重要度を付与して出力します。

| レベル | 意味 | Claude側の対応 |
|--------|------|----------------|
| **[BLOCKER]** | マージ不可 | 必ず修正が必要。ユーザーに報告し、修正を実施 |
| **[WARNING]** | 要検討 | リスクを説明し、ユーザーに判断を委ねる |
| **[INFO]** | 参考情報 | 参考として伝える。対応は任意 |

### BLOCKER の例

- セキュリティ脆弱性（SQLインジェクション、XSSなど）
- データ破損の可能性
- 本番障害リスク
- 設計の根本的な問題

### WARNING の例

- 設計方針との乖離
- パフォーマンス懸念
- 保守性の低下
- テストカバレッジ不足

### INFO の例

- コードスタイルの改善提案
- ベストプラクティスの紹介
- 代替アプローチの提案

---

## アイデア

- **並列作業モード**: 別ペインでcodexに作業させながら、メインのClaudeは別の作業を進められるように、対話形式でcodexを利用できるようにする

- **サブエージェント化によるコンテキスト最適化**: SKILL.md全文がメインコンテキストに読み込まれ、codexレスポンスも全文が会話履歴に残る問題がある。tdd-executor/verifierと同様にTask tool（subagent_type: second-opinion-executor）に委譲し、結果を要約（300-500文字）して返す形式にすることで、コンテキスト消費を90%以上削減できる可能性がある。
