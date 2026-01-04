# AI Development Directory

Claude Codeの開発支援ディレクトリ。`/dev` と `/verify` コマンドで使用する。

## ディレクトリ構造

```
ai/
├── board.md              # 作業ボード（現在の実装状況）
├── specs/                # 機能仕様（永続保存）
│   └── <feature>/
│       ├── requirements.md   # 要件定義
│       ├── design.md         # 設計
│       └── tasks.md          # タスク・進捗
└── README.md             # 本ファイル
```

## 運用フロー

### 1. 新規機能開始

```bash
# Devタブで実行
/dev <feature-name>
```

- `ai/specs/<feature>/` に仕様ファイルを作成
- `ai/board.md` の Current Work を更新
- 設計・実装を進める

### 2. 検証

```bash
# Verifyタブで実行
/verify full
```

- テスト実行、Lint、コードレビュー
- 結果を報告形式で出力
- Dev が `ai/board.md` の Verify Log に反映

### 3. コミット

```bash
# Devタブで実行
/dev commit
```

- CLAUDE.md のコミット分割ポリシーに従ってコミット
- `ai/board.md` の History に記録

## ファイル詳細

### board.md

現在の作業状況を俯瞰するボード。

| セクション | 内容 | 更新者 |
|------------|------|--------|
| Current Work | 実装中の機能・ブランチ | Dev |
| Active Tasks | 進行中のタスク | Dev |
| Verify Log | テスト・レビュー結果 | Dev（Verifyの報告を反映） |
| History | 作業履歴 | Dev |

### specs/<feature>/

機能ごとの仕様ドキュメント。完了後も振り返り可能。

| ファイル | 内容 |
|----------|------|
| requirements.md | 背景、課題、スコープ、受け入れ基準 |
| design.md | 設計判断、パッケージ構造、API仕様 |
| tasks.md | 実装タスク、テストシナリオ（TDD用）、進捗ログ |

## コマンドとスキル

### コマンド（エントリポイント）

| コマンド | 役割 | 編集権限 |
|----------|------|----------|
| `/dev` | 設計・実装・コミットを統合 | あり |
| `/verify` | テスト・レビューを統合 | なし（報告のみ） |

### スキル（再利用可能な機能）

| スキル | 役割 | 呼び出し元 |
|--------|------|------------|
| `/design` | 設計フェーズ（テストシナリオ含む） | `/dev <feature>` |
| `/implement` | TDD実装（Red→Green→Refactor） | `/dev continue` |
| `/commit` | コミット計画・実行 | `/dev commit` |
| `/test` | RSpec実行 | `/verify test` |
| `/lint` | 品質チェック | `/verify lint` |
| `/review` | コードレビュー | `/verify review` |

## 並列作業時の注意

Dev と Verify は同一ディレクトリを共有するため：

- **Verify はファイル編集しない**（コード、設定、board.md）
- **Verify は git 操作しない**（checkout, reset, commit 等）
- **結果は報告形式**で Dev に伝達し、Dev が反映する
