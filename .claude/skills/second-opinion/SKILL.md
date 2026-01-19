---
name: second-opinion
description: codex（OpenAI CLI）を呼び出してセカンドオピニオンを得る
---

あなたは Claude Code のセカンドオピニオン担当です。codex（OpenAI CLI）を使用して、第三者視点のレビューやアドバイスを取得します。

## 前提条件

このスキルを使用するには以下が必要です：

1. **tmux**: ターミナルマルチプレクサ
2. **codex**: OpenAI CLI（`npm install -g @openai/codex` または `npx codex`）
3. **tmuxセッション内で実行**: `$TMUX` 環境変数が設定されていること

## コマンド一覧

| コマンド | 説明 | スクリプト |
|----------|------|-----------|
| `/second-opinion start` | codexペインを起動 | `start.sh` |
| `/second-opinion stop` | codexペインを終了 | `stop.sh` |
| `/second-opinion status` | ペイン状態を確認 | `status.sh` |
| `/second-opinion ask <prompt>` | プロンプト送信 | `ask.sh` |
| `/second-opinion exec <prompt>` | ワンショット実行 | `exec.sh` |
| `/second-opinion review` | git diffレビュー | `review.sh` |
| `/second-opinion design <topic>` | 設計相談 | `design.sh` |

## モード別の動作

### `/second-opinion start` - codexペインを起動

tmuxで右側に新しいペインを作成し、codexを起動します。

**実行:** `.claude/skills/second-opinion/start.sh`

### `/second-opinion stop` - codexペインを終了

codexを終了し、ペインを閉じます。

**実行:** `.claude/skills/second-opinion/stop.sh`

### `/second-opinion status` - ペイン状態を確認

codexペインの状態を確認します。

**実行:** `.claude/skills/second-opinion/status.sh`

### `/second-opinion ask <prompt>` - プロンプト送信

起動中のcodexペインにプロンプトを送信します。

**実行:** `.claude/skills/second-opinion/ask.sh "<prompt>"`

### `/second-opinion exec <prompt>` - ワンショット実行

codexを一時的に起動してプロンプトを実行し、結果を取得します。ペインは使用せず、直接結果を返します。

**実行:** `.claude/skills/second-opinion/exec.sh "<prompt>"`

### `/second-opinion review` - git diffレビュー

現在のgit diffをcodexに送ってコードレビューを依頼します。

- ペイン起動中: ペインに送信
- ペイン未起動: ワンショット実行

**実行:** `.claude/skills/second-opinion/review.sh`

### `/second-opinion design <topic>` - 設計相談

設計についてセカンドオピニオンを求めます。`ai/specs/<topic>/` に設計ドキュメントがあれば参照します。

- ペイン起動中: ペインに送信
- ペイン未起動: ワンショット実行

**実行:** `.claude/skills/second-opinion/design.sh "<topic>"`

## エラーハンドリング

| エラー | 検出方法 | 対処 |
|--------|----------|------|
| codex未インストール | `command -v codex` | `npx codex` を試行。それも失敗なら `npm install -g @openai/codex` を案内 |
| tmux未インストール | `command -v tmux` | `brew install tmux` を案内 |
| tmuxセッション外 | `$TMUX` 変数が空 | `tmux new -s dev` でセッション開始を案内 |
| ペイン消失 | `tmux list-panes` | ファイル削除後、再起動を案内 |

## tmux構成イメージ

```
┌─────────────────────────────────┬───────────────────────────┐
│  Claude Code (Main)             │  Codex (Second Opinion)   │
│                                 │                           │
│  > /second-opinion start        │  $ codex --sandbox read-only
│  > /second-opinion ask "..."    │  > [prompt]               │
│                                 │  [response...]            │
│  > /second-opinion stop         │                           │
└─────────────────────────────────┴───────────────────────────┘
```

## ディレクトリ構成

```
.claude/skills/second-opinion/
├── SKILL.md      # このファイル（スキル定義）
├── lib.sh        # 共通ライブラリ（各スクリプトから source）
├── start.sh      # codexペイン起動
├── stop.sh       # codexペイン終了
├── status.sh     # ペイン状態確認
├── ask.sh        # プロンプト送信
├── exec.sh       # ワンショット実行
├── review.sh     # git diffレビュー
└── design.sh     # 設計相談
```

## 注意事項

- codexは `--sandbox read-only` モードで起動（安全性のため）
- ペインIDはプロジェクトディレクトリごとに管理（`/tmp/second-opinion-pane-<hash>`）
- 複数プロジェクトで同時に使用可能
- 長いプロンプト（特にgit diff）は一時ファイル経由で送信
