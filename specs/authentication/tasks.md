# 認証機能 実装タスク

> **実装者へ:** このドキュメントは architect が作成した初期ドラフトです。実装を進めながら適宜更新してください。

## 実装フェーズ

### フェーズ1: 基盤準備

- [x] **Gemfile に依存gem追加**
  ```ruby
  gem "rodauth-rails", "~> 1.15"
  gem "jwt", "~> 2.10"
  gem "bcrypt", "~> 3.1"
  ```
- [x] `bundle install` 実行
- [x] `app/packages/authentication/package.yml` 作成
  ```yaml
  enforce_dependencies: true
  enforce_privacy: true

  dependencies:
    - "."

  public_path: app/public
  ```
- [x] **検証コマンド:**
  ```bash
  bundle list | grep -E "(rodauth|jwt|bcrypt)"
  bundle exec packwerk validate
  ```
  **実行結果 (2025-10-15):**
  - bcrypt 3.1.20, jwt 2.10.2, rodauth 2.41.0, rodauth-model 0.4.0, rodauth-rails 1.15.2 インストール完了
  - Packwerk validation successful
- [ ] **コミット:** `chore(lockfile): 認証関連gemを追加`

---

### フェーズ2: Rodauth設定

- [x] **ディレクトリ作成**
  ```bash
  mkdir -p app/packages/authentication/app/lib
  mkdir -p app/packages/authentication/app/controllers/authentication
  mkdir -p app/packages/authentication/app/models
  mkdir -p app/packages/authentication/app/public/authentication
  ```

- [x] **Rodauth設定クラス作成**
  - ファイル: `app/packages/authentication/app/lib/rodauth_app.rb`
  - **実装結果 (2025-10-15):**
    - jwt_expiration パラメータは存在しないため削除
    - Sequel::DATABASES を使用してActiveRecord接続を構成
    - テーブル未作成時のスキーマチェックエラーは、フェーズ4のマイグレーション実行後に解消予定

- [x] **Rodauth初期化設定**
  - ファイル: `config/initializers/rodauth.rb`
  - **実装結果 (2025-10-15):**
    - sequel-activerecord_connection の設定を追加
    - after_initialize ブロックで遅延ロード

- [x] **環境変数設定**
  - `.env.example` に追加: ✅
  - `.env` ファイル作成（Git管理外）: ✅
  - `.gitignore` に `.env.example` の例外を追加: ✅
  - `dotenv-rails` gem を Gemfile に追加: ✅

- [x] **検証コマンド:**
  ```bash
  # Railsが起動できるか確認
  RAILS_ENV=test bin/rails runner "puts 'Rails loaded successfully'"
  # ✅ 成功（deprecation警告あり）
  ```
  **制約事項:**
  - Rodauth設定はaccountsテーブル存在チェックを行うため、フェーズ4マイグレーション後に完全動作予定
  - Lefthook pre-commit: RuboCop/Packwerk は成功、RSpec はテーブル未作成のため失敗（想定内）

- [ ] **コミット:** `feat(pack-authentication): Rodauth設定を追加`
- [ ] **コミット:** `chore(config): JWT環境変数を追加`
- [ ] **コミット:** `chore(lockfile): dotenv-rails を追加`

---

### フェーズ3: モデル実装

- [x] **Accountモデル作成**
  - ファイル: `app/packages/authentication/app/models/account.rb`
  - 内容:
    ```ruby
    class Account < ApplicationRecord
      validates :email, presence: true,
                        format: { with: URI::MailTo::EMAIL_REGEXP },
                        uniqueness: { case_sensitive: false }

      before_validation :normalize_email

      private

      def normalize_email
        self.email = email&.downcase&.strip
      end
    end
    ```
  - **実装結果 (2025-10-20):**
    - 設計書通りにバリデーション・正規化ロジックを実装
    - RuboCop: 違反なし
    - Packwerk: 違反なし
  - **追加変更 (2025-10-21):**
    - `status` カラムに Enum 定義を追加（型安全性向上）
    - Rodauth互換の文字列ベースEnum（unverified/verified/locked/closed）
    - `_prefix: true` で名前空間衝突を回避（`status_verified?` など）
    - 便利メソッド: `account.status_verified?`, `account.status_locked!`, `Account.status_verified` など

- [x] **検証コマンド:**
  ```bash
  # モデルが読み込まれるか確認
  RAILS_ENV=test bin/rails runner "puts Account.name"
  # ✅ 成功: "Account" が出力される
  ```

- [ ] **コミット:** `feat(pack-authentication): Accountモデルを追加`

---

### フェーズ4: マイグレーション作成・実行

- [x] **マイグレーション生成**
  ```bash
  bin/rails generate migration CreateAuthenticationTables
  ```
  - **実行結果 (2025-10-21):**
    - ファイル生成: `db/migrate/20251021025537_create_authentication_tables.rb`

- [x] **マイグレーションファイル編集**
  - ファイル: `db/migrate/20251021025537_create_authentication_tables.rb`
  - 内容:
    ```ruby
    class CreateAuthenticationTables < ActiveRecord::Migration[7.2]
      def change
        create_table :accounts do |t|
          t.string :email, null: false
          t.string :status, null: false, default: "verified"
          t.timestamps
        end
        add_index :accounts, :email, unique: true

        create_table :account_password_hashes do |t|
          t.bigint :account_id, null: false
          t.string :password_hash, null: false
        end
        add_index :account_password_hashes, :account_id, unique: true
        add_foreign_key :account_password_hashes, :accounts, on_delete: :cascade
      end
    end
    ```
  - **実装結果 (2025-10-21):**
    - 設計書通りに accounts / account_password_hashes テーブルを定義
    - emailにuniqueインデックス、account_idに外部キー制約を追加

- [x] **マイグレーション実行**
  ```bash
  # 開発環境
  bin/rails db:migrate
  # ✅ 成功: accounts / account_password_hashes テーブル作成

  # テスト環境
  RAILS_ENV=test bin/rails db:migrate
  # ✅ 成功
  ```

- [x] **検証コマンド:**
  ```bash
  # テーブルが作成されたか確認
  bin/rails runner "puts Account.table_name"
  # ✅ 出力: accounts

  bin/rails runner "puts Account.columns.map(&:name)"
  # ✅ 出力: id, email, status, created_at, updated_at
  ```
  - **重要:** schema.rb が自動生成されました！
  - マイグレーションファイル（変更履歴）から schema.rb（最終状態）が作成される流れを確認

- [ ] **コミット:** `chore(migration): 認証用テーブルを追加`
- [ ] **コミット:** `chore(schema): schema.rbを更新`

---

### フェーズ5: モデルのテスト実装

- [ ] **テストディレクトリ作成**
  ```bash
  mkdir -p app/packages/authentication/spec/models
  ```

- [ ] **Accountモデルのユニットテスト作成**
  - ファイル: `app/packages/authentication/spec/models/account_spec.rb`
  - 内容:
    ```ruby
    require "rails_helper"

    RSpec.describe Account, type: :model do
      describe "validations" do
        subject { Account.new(email: "test@example.com") }

        it { should validate_presence_of(:email) }
        it { should validate_uniqueness_of(:email).case_insensitive }

        context "email format validation" do
          it "accepts valid email addresses" do
            valid_emails = [
              "user@example.com",
              "user.name@example.co.jp",
              "user+tag@example.com"
            ]

            valid_emails.each do |email|
              account = Account.new(email: email)
              expect(account.valid?).to be(true), "Expected #{email} to be valid"
            end
          end

          it "rejects invalid email addresses" do
            invalid_emails = [
              "invalid",
              "@example.com",
              "user@",
              "user @example.com"
            ]

            invalid_emails.each do |email|
              account = Account.new(email: email)
              expect(account.valid?).to be(false), "Expected #{email} to be invalid"
            end
          end
        end

        context "uniqueness validation" do
          it "allows same email with different case" do
            Account.create!(email: "user@example.com")
            duplicate = Account.new(email: "USER@EXAMPLE.COM")

            expect(duplicate.valid?).to be(false)
            expect(duplicate.errors[:email]).to include("has already been taken")
          end
        end
      end

      describe "#normalize_email" do
        it "converts email to lowercase" do
          account = Account.create!(email: "USER@EXAMPLE.COM")
          expect(account.email).to eq("user@example.com")
        end

        it "strips whitespace" do
          account = Account.create!(email: "  user@example.com  ")
          expect(account.email).to eq("user@example.com")
        end

        it "handles nil email" do
          account = Account.new(email: nil)
          expect { account.valid? }.not_to raise_error
        end
      end
    end
    ```

- [ ] **テスト実行**
  ```bash
  bundle exec rspec app/packages/authentication/spec/models/account_spec.rb
  ```

- [ ] **検証コマンド:**
  ```bash
  # 全てのテストがパスすることを確認
  bundle exec rspec app/packages/authentication/spec/models/account_spec.rb --format documentation
  ```

- [ ] **コミット:** `test(pack-authentication): Accountモデルのテストを追加`

---

### フェーズ6: コントローラー実装

- [ ] **RegistrationsController作成**
  - ファイル: `app/packages/authentication/app/controllers/authentication/registrations_controller.rb`
  - 内容:
    ```ruby
    module Authentication
      class RegistrationsController < ApplicationController
        def create
          account = Account.new(email: params[:email])

          # Rodauthでアカウント作成 + JWT発行
          result = rodauth.create_account(
            login: params[:email],
            password: params[:password]
          )

          if result.success?
            render json: {
              jwt: rodauth.session_jwt,
              account: { id: account.id, email: account.email }
            }, status: :created
          else
            render json: {
              error: {
                code: "REGISTRATION_FAILED",
                message: result.error_message,
                trace_id: request.trace_id
              }
            }, status: :unprocessable_entity
          end
        end
      end
    end
    ```

- [ ] **SessionsController作成**
  - ファイル: `app/packages/authentication/app/controllers/authentication/sessions_controller.rb`
  - 内容:
    ```ruby
    module Authentication
      class SessionsController < ApplicationController
        def create
          result = rodauth.login(
            login: params[:email],
            password: params[:password]
          )

          if result.success?
            account = Account.find_by!(email: params[:email])
            render json: {
              jwt: rodauth.session_jwt,
              account: { id: account.id, email: account.email }
            }
          else
            render json: {
              error: {
                code: "LOGIN_FAILED",
                message: "Invalid email or password",
                trace_id: request.trace_id
              }
            }, status: :unauthorized
          end
        end
      end
    end
    ```

- [ ] **ルーティング追加**
  - ファイル: `config/routes.rb`
  - 追加内容:
    ```ruby
    namespace :api do
      namespace :v1 do
        namespace :auth do
          post :register, to: "authentication/registrations#create"
          post :login, to: "authentication/sessions#create"
        end
      end
    end
    ```

- [ ] **検証コマンド:**
  ```bash
  # ルートが登録されているか確認
  bin/rails routes | grep auth
  ```

- [ ] **コミット:** `feat(pack-authentication): 登録・ログインAPIを追加`
- [ ] **コミット:** `chore(routes): 認証ルートを追加`

---

### フェーズ7: 公開API実装

- [ ] **Authenticatable concern作成**
  - ファイル: `app/packages/authentication/app/public/authentication/authenticatable.rb`
  - 内容:
    ```ruby
    module Authentication
      module Authenticatable
        extend ActiveSupport::Concern

        included do
          attr_reader :current_account
        end

        private

        def authenticate_account!
          token = extract_token_from_header

          return unauthorized_response unless token

          payload = decode_jwt(token)
          @current_account = Account.find_by(id: payload["account_id"])

          unauthorized_response unless @current_account
        rescue JWT::DecodeError, JWT::ExpiredSignature
          unauthorized_response
        end

        def extract_token_from_header
          header = request.headers["Authorization"]
          header&.split(" ")&.last if header&.start_with?("Bearer ")
        end

        def decode_jwt(token)
          JWT.decode(
            token,
            ENV.fetch("JWT_SECRET_KEY"),
            true,
            algorithm: "HS256"
          ).first
        end

        def unauthorized_response
          render json: {
            error: {
              code: "UNAUTHORIZED",
              message: "Invalid or expired token",
              trace_id: request.trace_id
            }
          }, status: :unauthorized

          false  # before_actionチェーンを停止
        end
      end
    end
    ```

- [ ] **ApplicationControllerに組み込み**
  - ファイル: `app/controllers/application_controller.rb`
  - 追加内容:
    ```ruby
    class ApplicationController < ActionController::API
      include Authentication::Authenticatable  # 追加

      # 各コントローラーで必要に応じて有効化
      # before_action :authenticate_account!
    end
    ```

- [ ] **検証コマンド:**
  ```bash
  # ApplicationControllerが正常に読み込まれるか確認
  RAILS_ENV=test bin/rails runner "puts ApplicationController.ancestors.include?(Authentication::Authenticatable)"
  ```

- [ ] **コミット:** `feat(pack-authentication): 認証concernを追加`

---

### フェーズ8: リクエストスペック実装

- [ ] **テストディレクトリ作成**
  ```bash
  mkdir -p app/packages/authentication/spec/requests/authentication
  ```

- [ ] **RegistrationsController リクエストスペック**
  - ファイル: `app/packages/authentication/spec/requests/authentication/registrations_spec.rb`
  - 内容:
    ```ruby
    require "rails_helper"
    require "swagger_helper"

    RSpec.describe "POST /api/v1/auth/register", type: :request do
      describe "正常系" do
        it "creates account and returns JWT" do
          post "/api/v1/auth/register", params: {
            email: "newuser@example.com",
            password: "secure_password123"
          }

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)

          expect(json["jwt"]).to be_present
          expect(json["account"]["email"]).to eq("newuser@example.com")
          expect(Account.find_by(email: "newuser@example.com")).to be_present
        end
      end

      describe "異常系" do
        it "returns error for duplicate email" do
          Account.create!(email: "existing@example.com")

          post "/api/v1/auth/register", params: {
            email: "existing@example.com",
            password: "password123"
          }

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)

          expect(json["error"]["code"]).to eq("REGISTRATION_FAILED")
          expect(json["error"]["trace_id"]).to be_present
        end

        it "returns error for invalid email format" do
          post "/api/v1/auth/register", params: {
            email: "invalid-email",
            password: "password123"
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error for missing password" do
          post "/api/v1/auth/register", params: {
            email: "user@example.com",
            password: ""
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
    ```

- [ ] **SessionsController リクエストスペック**
  - ファイル: `app/packages/authentication/spec/requests/authentication/sessions_spec.rb`
  - 内容:
    ```ruby
    require "rails_helper"
    require "swagger_helper"

    RSpec.describe "POST /api/v1/auth/login", type: :request do
      let!(:account) do
        # Rodauth経由でアカウント作成（実際の実装に合わせて調整）
        Account.create!(email: "user@example.com")
        # TODO: パスワードハッシュも設定する必要あり
      end

      describe "正常系" do
        it "returns JWT for valid credentials" do
          post "/api/v1/auth/login", params: {
            email: "user@example.com",
            password: "correct_password"
          }

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)

          expect(json["jwt"]).to be_present
          expect(json["account"]["email"]).to eq("user@example.com")
        end
      end

      describe "異常系" do
        it "returns error for invalid password" do
          post "/api/v1/auth/login", params: {
            email: "user@example.com",
            password: "wrong_password"
          }

          expect(response).to have_http_status(:unauthorized)
          json = JSON.parse(response.body)

          expect(json["error"]["code"]).to eq("LOGIN_FAILED")
          expect(json["error"]["message"]).to eq("Invalid email or password")
        end

        it "returns error for non-existent email" do
          post "/api/v1/auth/login", params: {
            email: "nonexistent@example.com",
            password: "password123"
          }

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
    ```

- [ ] **JWT検証のテスト（サンプル）**
  - ファイル: `app/packages/authentication/spec/requests/authentication/jwt_verification_spec.rb`
  - 内容:
    ```ruby
    require "rails_helper"

    RSpec.describe "JWT Verification", type: :request do
      # テスト用の保護されたエンドポイントを作成
      # （実際には他パッケージで使用される想定）

      let(:account) { Account.create!(email: "user@example.com") }
      let(:valid_jwt) do
        JWT.encode(
          { account_id: account.id, exp: 1.hour.from_now.to_i },
          ENV.fetch("JWT_SECRET_KEY"),
          "HS256"
        )
      end

      describe "with valid JWT" do
        it "allows access to protected resource" do
          # TODO: 実際の保護されたエンドポイントでテスト
        end
      end

      describe "without JWT" do
        it "returns 401 Unauthorized" do
          # TODO: Authorizationヘッダーなしでアクセス
        end
      end

      describe "with invalid JWT" do
        it "returns 401 Unauthorized" do
          get "/api/v1/protected_resource", headers: {
            "Authorization" => "Bearer invalid_token"
          }

          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "with expired JWT" do
        it "returns 401 Unauthorized" do
          expired_jwt = JWT.encode(
            { account_id: account.id, exp: 1.hour.ago.to_i },
            ENV.fetch("JWT_SECRET_KEY"),
            "HS256"
          )

          get "/api/v1/protected_resource", headers: {
            "Authorization" => "Bearer #{expired_jwt}"
          }

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
    ```

- [ ] **テスト実行**
  ```bash
  bundle exec rspec app/packages/authentication/spec/requests/
  ```

- [ ] **コミット:** `test(pack-authentication): リクエストスペックを追加`

---

### フェーズ9: RSwag統合

- [ ] **RSwag設定追加**
  - `spec/requests/authentication/registrations_spec.rb` に追加:
    ```ruby
    path "/api/v1/auth/register" do
      post "Register new account" do
        tags "Authentication"
        consumes "application/json"
        produces "application/json"

        parameter name: :registration, in: :body, schema: {
          type: :object,
          properties: {
            email: { type: :string, format: :email },
            password: { type: :string, minLength: 8 }
          },
          required: ["email", "password"]
        }

        response "201", "account created" do
          schema type: :object,
                 properties: {
                   jwt: { type: :string },
                   account: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       email: { type: :string }
                     }
                   }
                 }

          run_test!
        end

        response "422", "validation error" do
          run_test!
        end
      end
    end
    ```

- [ ] **Swagger YAML生成**
  ```bash
  RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
  ```

- [ ] **検証コマンド:**
  ```bash
  # Swagger UIで確認
  bin/rails s
  # ブラウザで http://localhost:3000/api-docs を開く
  ```

- [ ] **コミット:** `chore(swagger): 認証API仕様を生成`

---

### フェーズ10: 統合テスト・品質チェック

- [ ] **全テスト実行**
  ```bash
  bundle exec rspec
  ```

- [ ] **RuboCop実行**
  ```bash
  bundle exec rubocop -a app/packages/authentication/
  ```

- [ ] **Packwerkチェック**
  ```bash
  bundle exec packwerk validate
  bundle exec packwerk check app/packages/authentication/
  ```

- [ ] **セキュリティスキャン**
  ```bash
  bundle exec brakeman -q
  bundle exec bundler-audit check --update
  ```

- [ ] **手動テスト（curl）**

  **ユーザー登録:**
  ```bash
  curl -X POST http://localhost:3000/api/v1/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"secure_password123"}'
  ```

  **ログイン:**
  ```bash
  curl -X POST http://localhost:3000/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"secure_password123"}'
  ```

  **保護されたエンドポイントアクセス（将来）:**
  ```bash
  JWT="<上記で取得したJWT>"
  curl -X GET http://localhost:3000/api/v1/protected_resource \
    -H "Authorization: Bearer $JWT"
  ```

- [ ] **検証項目チェックリスト:**
  - [ ] 全テストがパス（緑色）
  - [ ] RuboCop違反なし
  - [ ] Packwerk依存関係違反なし
  - [ ] Brakemanで重大な脆弱性なし
  - [ ] curlでユーザー登録成功
  - [ ] curlでログイン成功
  - [ ] JWTが返却される
  - [ ] 無効なJWTで401エラー

- [ ] **コミット（必要に応じて）:** `chore(rubocop): コードスタイルを修正`

---

## テスト観点まとめ

### ユニットテスト（Model）
- [x] メールアドレス必須
- [x] メールアドレス形式検証
- [x] メールアドレス一意性（大文字小文字区別なし）
- [x] メールアドレス正規化（小文字変換）
- [x] メールアドレス正規化（空白除去）
- [x] nil email の処理

### リクエストテスト（API）
- [x] 登録: 正常系（JWT発行）
- [x] 登録: メールアドレス重複エラー
- [x] 登録: 無効なメール形式エラー
- [x] 登録: パスワード未入力エラー
- [x] ログイン: 正常系（JWT発行）
- [x] ログイン: パスワード誤りエラー
- [x] ログイン: 未登録メールエラー
- [x] JWT検証: 有効なトークンでアクセス成功
- [x] JWT検証: トークンなしで401
- [x] JWT検証: 無効なトークンで401
- [x] JWT検証: 期限切れトークンで401

### セキュリティテスト
- [ ] パスワードが平文でDBに保存されない
- [ ] JWT秘密鍵が環境変数管理
- [ ] ログイン失敗時にアカウント存在を推測できない
- [ ] SQLインジェクション対策（パラメータ化クエリ）

---

## 実装完了後の引き継ぎ事項

### 次のステップ（将来対応）
1. トークンリフレッシュ機能
2. パスワードリセット機能（メール送信）
3. レート制限（Rack::Attack）
4. アカウントロック機能
5. ログイン履歴管理

### ドキュメント更新
- [ ] `README.md` に認証機能の説明を追加
- [ ] `doc/authentication.md` に詳細ドキュメント作成（任意）
- [ ] `CLAUDE.md` に認証機能のセクション追加（任意）

### 他パッケージへの展開
他のドメインパッケージ（例: `payment`, `invoice`）で認証機能を利用する場合:

1. **package.yml に依存追加:**
   ```yaml
   dependencies:
     - "."
     - "app/packages/authentication"
   ```

2. **Controller で認証を有効化:**
   ```ruby
   class Payment::InvoicesController < ApplicationController
     before_action :authenticate_account!

     def index
       invoices = current_account.invoices
       render json: invoices
     end
   end
   ```

---

**実装者へ:** 不明点があれば `specs/authentication/` 配下のドキュメントを参照してください。設計判断の背景は `design.md`、要件の詳細は `requirements.md` に記載されています。
