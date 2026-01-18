# CLAUDE.md

ユーザーには日本語で応答してください。

## 概要

Ruby on Rails 7.2の企業向け支払い管理システム（モジュラーモノリス）。

詳細: `.claude/rules/project-overview.md`

## クイックスタート

| 目的 | コマンド |
|------|----------|
| 新機能開発 | `/dev <feature>` |
| 実装（TDD） | `/dev` |
| 検証 | `/verify full` |
| コミット | `/dev commit` |
| PR作成 | `/dev pr` |

## 開発コマンド（抜粋）

```bash
bundle exec rspec                    # テスト
bundle exec rubocop                  # Lint
bundle exec packwerk check           # パッケージ境界
bundle exec brakeman -q              # セキュリティ
```

詳細: `.claude/rules/development-commands.md`

## ドキュメント構成

| ディレクトリ | 内容 |
|-------------|------|
| `.claude/rules/` | ナレッジ・方針 |
| `.claude/skills/` | ワークフロー（/dev, /verify等） |
| `.claude/agents/` | 自律エージェント |

### rules/一覧

| ファイル | 内容 |
|----------|------|
| `project-overview.md` | 技術スタック・認証方針 |
| `ai-workflow.md` | AI開発ディレクトリ運用 |
| `architecture.md` | モジュラーモノリス・Packwerk |
| `development-commands.md` | 開発・テスト・品質チェック |
| `technical-features.md` | ログ・エラーハンドリング |
| `rubocop-config.md` | RuboCop設定 |
| `utility-commands.md` | DB・ユーティリティ |

## 参考ドキュメント

- `ai/README.md` - AI開発ガイド
- `doc/modular_monolith.md` - アーキテクチャ詳細
- `doc/packwerk_guide.md` - Packwerk使用方法
- `doc/error_handling.md` - エラーハンドリングの詳細
- `doc/logging_tracing.md` - ログとトレーシングの詳細
- `doc/api_documentation.md` - API仕様書ガイド
- `doc/static_analysis.md` - 静的解析と品質チェック
