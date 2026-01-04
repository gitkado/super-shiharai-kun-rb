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
- **認証**: BCrypt + JWT（Rodauth不使用）

### 認証実装の方針（重要）

本プロジェクトの認証機能は **BCrypt + JWT gem の直接利用** により実装されています。

**現在の実装:**
- `app/packages/authentication/` パッケージ配下
- BCryptによるパスワードハッシュ化（`AccountPasswordHash`モデル）
- JWT gemによるトークン認証（`Authentication::JwtService`公開API）
- エンドポイント: `POST /api/v1/auth/register`, `POST /api/v1/auth/login`

**この設計判断の理由:**
1. **本プロジェクトの主目的は請求管理ドメインの実装**であり、認証は標準的な実装で十分
2. **シンプルさ優先**: RailsのFat Model, Skinny Controller方針に従い、保守しやすい構成
3. **将来の拡張性**: パスワードリセット・2FA等が必要になれば、Rodauthへの段階的移行も可能

**重要: Rodauthについて**
- `rodauth-rails` gemは依存関係に含まれていますが、**現在は直接利用していません**（将来の拡張用に保持）
- 新規認証機能を実装する際は、まずBCrypt + JWTの枠内で実装できないか検討すること
- Rodauth導入を提案する場合は、その必要性を明確に説明し、ユーザーの承認を得ること

## AI開発ディレクトリ（`ai/`）

Claude Codeの `/dev` と `/verify` コマンドが使用する開発支援ディレクトリ。

### ディレクトリ構造

```
ai/
├── board.md              # 作業ボード（現在の実装状況）
├── specs/                # 機能仕様（永続保存）
│   └── <feature>/
│       ├── requirements.md
│       ├── design.md
│       └── tasks.md
└── README.md             # 運用ガイド
```

### 運用フロー

1. **新規機能開始**: `/dev <feature>` → `ai/specs/<feature>/` に仕様作成、`ai/board.md` に進捗記録
2. **検証**: `/verify full` → テスト・Lint・レビューを実行、結果を報告
3. **コミット**: `/dev commit` → コミット分割ポリシーに従ってコミット

### タブ分離（並列作業）

| タブ | コマンド | 役割 | 編集権限 |
|------|----------|------|----------|
| Dev | `/dev` | 設計・実装・コミット | あり |
| Verify | `/verify` | テスト・レビュー | なし（報告のみ） |

詳細ガイド: `ai/README.md`

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
# 全テスト実行（ランダム順序・シード値で再現性を担保）
bundle exec rspec

# 特定のファイルのテスト
bundle exec rspec spec/requests/hello_spec.rb

# 特定の行のテストのみ
bundle exec rspec spec/requests/hello_spec.rb:10

# fail-fast（最初のエラーで停止）
bundle exec rspec --fail-fast

# 特定のシード値で実行（再現テスト）
bundle exec rspec --seed 12345

# テスト環境のデータベース準備
RAILS_ENV=test bin/rails db:create db:migrate
```

**テスト品質ツール:**

- **Bullet**: テスト環境で有効化され、N+1クエリを自動検出してログに出力
- **SimpleCov**: テスト実行時にカバレッジを自動計測（`coverage/` ディレクトリに出力）
- **RSpec設定**: ランダム実行（`--order random`）でテスト間の依存を防止

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
- RSpec（fail-fast、DB自動準備）

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

### カスタムスラッシュコマンド

Claude Code専用のカスタムコマンドとスキルが定義されています。

#### コマンド（`.claude/commands/`）

| コマンド | 役割 | タブ |
|----------|------|------|
| `/dev` | 設計・実装・コミットを統合 | Dev |
| `/verify` | テスト・レビューを統合 | Verify |

#### スキル（`.claude/skills/`）

| スキル | 役割 | 呼び出し元 |
|--------|------|------------|
| `/design` | 設計フェーズ（要件定義・設計判断・テストシナリオ） | `/dev <feature>` |
| `/implement` | TDD実装フェーズ（Red→Green→Refactor） | `/dev continue` |
| `/commit` | コミット計画・実行 | `/dev commit` |
| `/test` | RSpec実行 | `/verify test` |
| `/lint` | 品質チェック（RuboCop・Packwerk・Brakeman） | `/verify lint` |
| `/review` | コードレビュー | `/verify review` |

#### 使用例

```bash
# Devタブ
/dev invoice-approval    # 新規機能開始 → /design スキル
/dev continue            # 作業継続 → /implement スキル
/dev commit              # コミット作成 → /commit スキル

# Verifyタブ
/verify full             # テスト + Lint + レビュー
/verify test             # テストのみ → /test スキル
/verify lint             # Lintのみ → /lint スキル
/verify review           # レビューのみ → /review スキル
```

## アーキテクチャ

### モジュラーモノリスの構造

```text
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
- 公開API配置のパターン:
  - ActiveRecordモデル: `app/public/*.rb` (public直下)
  - サービスクラス: `app/public/<module>/*.rb`
  - Concern: `app/public/**/*able.rb` (*ableで終わる命名規則推奨)

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
- Swagger UI: <http://localhost:3000/api-docs>
- 定義ファイル: `swagger/v1/swagger.yaml`

## RuboCopの設定

- ベース: `rubocop-rails-omakase`
- プラグイン: `rubocop-packs`, `rubocop-rspec`
- Packwerk境界の強制:
  - `Packs/ClassMethodsAsPublicApis`: 有効（パターンマッチングで例外管理）
    - ActiveRecordモデル: `app/packages/*/app/public/*.rb`
    - Concern: `app/packages/*/app/public/**/*able.rb`
  - `Packs/RootNamespaceIsPackName`: 有効
- frozen_string_literal: 常に有効（自動修正可能）
- Sorbetのcops: すべて無効化（Sorbetを利用していないため）

## コミット分割ポリシー（/dev commit 向け）

`/dev commit` 実行時は、以下のルールに従ってコミットを分割・命名すること。

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

### TDD単位のコミット（推奨）

TDDサイクルごとにコミットを分割することを推奨:

- `test(pack-<domain>)`: テストケース追加（Red Phase完了時）
- `feat(pack-<domain>)`: 機能実装（Green Phase完了時）
- `refactor(pack-<domain>)`: リファクタリング（Refactor Phase完了時、変更がある場合のみ）

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
  ```

- **フッター**: Claude Code生成マーカーやCo-Authored-Byトレーラーは**含めない**
  - GitHubで「gitkado and Claude committed」と表示されることを避けるため
  - コミットの作成者は常に `gitkado <gitkado@gmail.com>` のみ

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

- `ai/README.md` - AI開発ディレクトリ運用ガイド
- `ai/specs/vscode-lsp-setup/` - VS Code + Ruby LSP導入ガイド（開発環境セットアップ）
- `doc/modular_monolith.md` - モジュラーモノリスアーキテクチャの詳細
- `doc/packwerk_guide.md` - Packwerk使用方法
- `doc/error_handling.md` - エラーハンドリングの詳細
- `doc/logging_tracing.md` - ログとトレーシングの詳細
- `doc/api_documentation.md` - API仕様書ガイド
- `doc/static_analysis.md` - 静的解析と品質チェック
