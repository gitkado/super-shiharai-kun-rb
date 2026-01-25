# 開発コマンド

## 環境セットアップ

```bash
# Ruby環境確認（asdf使用時）
asdf current ruby

# PostgreSQL起動
docker compose up -d

# 依存関係インストール
bundle install

# データベース作成・マイグレーション
bin/rails db:create db:migrate

# アプリケーション起動
bin/rails s
```

**railsコマンドの使い分け:**

- `bin/rails` を優先（binstubsを使用）
- 明示的にgemのrailsを使う必要がある場合のみ `bundle exec rails`

## テスト・品質チェック

テスト・Lint実行は `/verify` スキルを使用。詳細: `.claude/skills/verify.md`

**主要コマンド:**

```bash
bundle exec rspec                    # テスト
bundle exec rubocop                  # コードスタイル
bundle exec packwerk check           # パッケージ境界
bundle exec brakeman -q              # セキュリティ
bundle exec bundler-audit check      # 依存gem脆弱性
npx markdownlint-cli2 "**/*.md"      # Markdownスタイル
```

**テスト品質ツール:**

- **Bullet**: テスト環境で有効化され、N+1クエリを自動検出してログに出力
- **SimpleCov**: テスト実行時にカバレッジを自動計測（`coverage/` ディレクトリに出力）
- **RSpec設定**: ランダム実行（`--order random`）でテスト間の依存を防止

**トラブルシューティング:** bundler-auditでエラーが発生した場合

```bash
rm -rf ~/.local/share/ruby-advisory-db
bundle exec bundler-audit update
```

## API仕様書生成

```bash
# Swagger YAML生成（RSpecから自動生成）
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# Swagger UI確認
# http://localhost:3000/api-docs
```

## Git Hooks（Lefthook）

Lefthookによる自動チェックが設定済み:

**pre-commit:**

- RuboCop（変更ファイルのみ）
- Packwerk validate + check（変更ファイルのみ）
- RSpec（fail-fast、DB自動準備）
- markdownlint（変更ファイルのみ）

**pre-push:**

- Brakeman（セキュリティスキャン）
- Bundler Audit（依存gem脆弱性チェック）
- RSpec（全テスト、DB自動準備）

**重要:** RSpec実行前に自動的に`db:test:prepare`が実行され、テストDB が常にクリーンな状態で実行されます。

**フックをスキップ:**

```bash
# 全てのフックをスキップ（緊急時のみ）
LEFTHOOK=0 git commit -m "message"

# 特定のタグのみスキップ
LEFTHOOK_EXCLUDE=test git commit -m "message"
```
