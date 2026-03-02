# CLAUDE.md

ユーザーには日本語で応答してください。

## コア原則

- 動作を証明（テスト通過）するまでタスクを完了とマークしない
- 「シニアエンジニアがレビューして承認するか？」を自問する
- 一時的な修正（ワークアラウンド）より根本解決を優先
- 変更は必要最小限に留める（影響範囲の最小化）
- 不明点はユーザーに確認し、推測で進めない
- セッション開始時に `ai/lessons.md` をレビューし、過去の教訓を確認する

## 禁止事項

- `app/` 直下にビジネスロジックを書かない（→ `app/packages/` へ）
- Rodauthを新規導入しない（BCrypt+JWTで実装）
- パッケージ間の循環依存を作らない
- テストなしでタスクを完了にしない
- 他パッケージの非公開クラスを直接参照しない（`app/public/` 経由のみ）

## 概要

Ruby on Rails 7.2の企業向け支払い管理システム（モジュラーモノリス）。

詳細: `.claude/rules/project-overview.md`

## クイックスタート

| 目的 | コマンド |
|------|----------|
| 新機能開発 | `/dev <feature>` |
| 実装（TDD） | `/dev` |
| 検証 | `/verify full` |
| コミット | `/commit-diff` |
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

## 参考ドキュメント

- `ai/README.md` - AI開発ガイド
- `ai/lessons.md` - 過去の教訓・改善ルール
- `doc/modular_monolith.md` - アーキテクチャ詳細
- `doc/packwerk_guide.md` - Packwerk使用方法
- `doc/error_handling.md` - エラーハンドリングの詳細
- `doc/logging_tracing.md` - ログとトレーシングの詳細
- `doc/api_documentation.md` - API仕様書ガイド
- `doc/static_analysis.md` - 静的解析と品質チェック
