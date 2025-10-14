# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

ユーザーには日本語で応答してください。

## プロジェクト概要

Ruby on Rails 7.2で構築した企業向け支払い管理システムのREST APIサービス。**モジュラーモノリス**アーキテクチャを採用し、Packwerkによるパッケージ境界の強制を行っています。

- Ruby 3.4.6（asdfまたはrbenv推奨、`.tool-versions`と`.ruby-version`参照）
- Rails 7.2.2
- PostgreSQL 16 (Docker)
- Redis 7
- Sidekiq (非同期ジョブ処理、将来実装予定)
- RSpec 7.1
- Packwerk 3.2 (パッケージ管理)

## 開発コマンド

### 環境セットアップ
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

### テスト実行
```bash
# 全テスト実行
bundle exec rspec

# 特定のファイルのテスト
bundle exec rspec spec/requests/hello_spec.rb

# 特定の行のテストのみ
bundle exec rspec spec/requests/hello_spec.rb:10

# fail-fast（最初のエラーで停止）
bundle exec rspec --fail-fast

# テスト環境のデータベース準備
RAILS_ENV=test bin/rails db:create db:migrate
```

### コード品質チェック
```bash
# RuboCop（コードスタイル自動修正）
bundle exec rubocop -a

# RuboCop（自動修正可能なものを全て修正）
bundle exec rubocop -A

# RuboCop（チェックのみ）
bundle exec rubocop

# 特定ファイルのみチェック
bundle exec rubocop app/packages/hello/

# Packwerk設定検証
bundle exec packwerk validate

# Packwerk依存関係チェック（全体）
bundle exec packwerk check

# 特定パッケージのみチェック
bundle exec packwerk check app/packages/hello/

# セキュリティスキャン
bundle exec brakeman -q

# 依存gem脆弱性チェック
bundle exec bundler-audit check --update
```

### API仕様書生成
```bash
# Swagger YAML生成（RSpecから自動生成）
RAILS_ENV=test bundle exec rake rswag:specs:swaggerize

# Swagger UI確認
# http://localhost:3000/api-docs
```

### Git Hooks（Lefthook）
Lefthookによる自動チェックが設定済み:

**pre-commit:**
- RuboCop（変更ファイルのみ）
- Packwerk validate + check（変更ファイルのみ）
- RSpec（fail-fast）

**pre-push:**
- Brakeman（セキュリティスキャン）
- Bundler Audit（依存gem脆弱性チェック）
- RSpec（全テスト）

**フックをスキップ:**
```bash
# 全てのフックをスキップ（緊急時のみ）
LEFTHOOK=0 git commit -m "message"

# 特定のタグのみスキップ
LEFTHOOK_EXCLUDE=test git commit -m "message"
```

## アーキテクチャ

### モジュラーモノリスの構造

```
app/
├── controllers/         # 共通基盤 - ApplicationControllerと技術的concernのみ
├── models/              # 共通基盤 - ApplicationRecordと技術的concernのみ
├── jobs/                # 共通基盤 - ApplicationJobのみ
├── mailers/             # 共通基盤 - ApplicationMailerのみ
├── middleware/          # Rackミドルウェア（RequestTraceIdなど）
└── packages/            # ビジネスロジック層（全てのドメイン機能）
    └── hello/           # Helloドメイン（サンプル）
        ├── package.yml  # パッケージ設定
        ├── app/
        │   ├── controllers/  # 非公開（内部実装）
        │   └── public/       # 公開API（他パッケージから利用可能）
        └── spec/
```

### 重要な原則

**app直下（共通基盤・インフラ層）:**
- ✅ 基底クラス（Application*）
- ✅ 全パッケージで共有する技術的な機能
- ✅ Rackミドルウェア
- ❌ ビジネスロジック → `app/packages/` へ

**app/packages/（ビジネスロジック層）:**
- ✅ 全てのドメイン固有のController, Model, Job, Mailer
- ✅ ビジネスルール、機能実装
- ✅ Railsの標準構成（MVC）に従う
- ✅ Fat Model, Skinny Controller

**公開APIの方針:**
- デフォルトは全て非公開（packages内のapp/配下）
- 他パッケージから利用されるものだけ `app/public/` に配置

### 新しいパッケージの追加

```bash
# 1. ディレクトリ構造作成
mkdir -p app/packages/your_domain/app/{controllers,models,jobs}
mkdir -p app/packages/your_domain/spec/requests

# 2. package.yml作成
cat > app/packages/your_domain/package.yml <<EOF
enforce_dependencies: true
enforce_privacy: true

dependencies:
  - "."  # ルートパッケージ（ApplicationControllerなど）
  # - "app/packages/authentication"  # 必要に応じて追加

public_path: app/public
EOF

# 3. Packwerkチェック
bundle exec packwerk validate
bundle exec packwerk check
```

### パッケージ間の依存関係ルール
- 各ドメインパッケージはルートパッケージに依存できる
- **循環依存は禁止**（Packwerkが検出）
- 他パッケージの非公開クラスへの直接参照は禁止（`app/public/` のみアクセス可能）

## 技術的な特徴

### 構造化ログ（SemanticLogger）
- 全環境でJSON形式出力
- リクエストごとに自動付与される `trace_id` で横断的な追跡が可能
- エラーレスポンスに `trace_id` を含めることでログとの紐付けが可能

### グローバルエラーハンドリング
- 統一されたエラーレスポンス形式（JSON）
- トレースID連携
- カスタムエラー対応: ビジネスロジック固有のエラーは `DomainError` を継承

エラーレスポンス例:
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Couldn't find User with 'id'=999",
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  }
}
```

### API仕様書（RSwag）
- RSpecのリクエストスペックから自動生成
- Swagger UI: http://localhost:3000/api-docs
- 定義ファイル: `swagger/v1/swagger.yaml`

## RuboCopの設定

- ベース: `rubocop-rails-omakase`
- プラグイン: `rubocop-packs`, `rubocop-rspec`
- Packwerk境界の強制:
  - `Packs/ClassMethodsAsPublicApis`: 有効
  - `Packs/RootNamespaceIsPackName`: 有効
- frozen_string_literal: 常に有効（自動修正可能）

## コミット分割ポリシー（Claude/committer向け）

Claudeのcommitterサブエージェントは、以下のルールに従ってコミットを分割・命名すること。

### 優先的に分離する対象
- `db/migrate/*.rb` → `chore(migration)` または `feat(db)`（単独コミット）
- `db/schema.rb` → `chore(schema)`（単独コミット）
- `Gemfile.lock` → `chore(lockfile)`（単独コミット）
- `swagger/**/*.yaml` → `chore(swagger)`（単独コミット）
- `config/routes.rb` → `chore(routes)`（単独コミット）

### ドメイン/パッケージ単位
- `app/packages/<domain>/` ごとにコミットを分ける。
- コミット種別:  
  - 実装: `feat(pack-<domain>)` / `fix(pack-<domain>)` / `refactor(pack-<domain>)`
  - テスト: `test(pack-<domain>)`
- 例:  
  - `feat(pack-payment): 承認APIを追加`  
  - `test(pack-payment): 承認APIの異常系を追加`

### 横断的な変更
- `config/`（routes除く） → `chore(config)`
- `app/middleware/` → `feat|refactor(middleware)`
- `doc/`, `README`, `CHANGELOG` → `docs`

### コミットメッセージの形式
- **タイトル**: 50〜72文字以内、日本語で要約（Conventional Commits準拠）  
  - 例: `feat(pack-user): ユーザー認証APIを追加`
- **本文**: 箇条書きで「Before / After / 影響 / リスク / rollback / 関連Issue」
  ```text
  - Before: ユーザー登録後に自動ログインされない
  - After: 登録成功時にJWTを発行
  - 影響: ログインAPIへの依存
  - rollback: revert可、スキーマ変更なし
  - Related: #123

## その他のコマンド

### ヘルスチェック
```bash
# アプリケーションが起動しているか確認
curl -if http://localhost:3000/up
```

### データベース操作
```bash
# マイグレーション実行
bin/rails db:migrate

# ロールバック
bin/rails db:rollback

# データベースリセット（開発環境のみ）
bin/rails db:reset

# シードデータ投入
bin/rails db:seed
```

**データベース接続情報:**
- `config/database.yml` および `docker-compose.yml` を参照
- デフォルト: PostgreSQL on localhost:5432

### コンソール
```bash
# Railsコンソール起動
bin/rails console

# 特定環境で起動
RAILS_ENV=test bin/rails console
```

## 参考ドキュメント

詳細は以下を参照:
- `doc/modular_monolith.md` - モジュラーモノリスアーキテクチャの詳細
- `doc/packwerk_guide.md` - Packwerk使用方法
- `doc/error_handling.md` - エラーハンドリングの詳細
- `doc/logging_tracing.md` - ログとトレーシングの詳細
- `doc/api_documentation.md` - API仕様書ガイド
- `doc/static_analysis.md` - 静的解析と品質チェック
