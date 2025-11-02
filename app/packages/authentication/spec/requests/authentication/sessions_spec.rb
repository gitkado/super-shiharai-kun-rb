# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/LetSetup
RSpec.describe "POST /api/v1/auth/login", type: :request do
  # テストデータ準備用のヘルパーメソッド
  # Rodauth経由でアカウント+パスワードハッシュを作成
  define_method(:create_test_account) do |email:, password:|
    account = Account.create!(email: email, status: "verified")

    # パスワードハッシュを作成（BCryptで生成）
    password_hash = BCrypt::Password.create(password, cost: BCrypt::Engine::MIN_COST)
    AccountPasswordHash.create!(account_id: account.id, password_hash: password_hash)

    account
  end

  describe "正常系: ログイン成功とJWT発行" do
    let!(:account) { create_test_account(email: "user@example.com", password: "correct_password") }

    it "returns JWT for valid credentials" do
      post "/api/v1/auth/login", params: {
        email: "user@example.com",
        password: "correct_password"
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # JWTが発行されることを確認
      expect(json["jwt"]).to be_present
      expect(json["jwt"]).to be_a(String)

      # アカウント情報が返却されることを確認
      expect(json["account"]).to be_present
      expect(json["account"]["id"]).to eq(account.id)
      expect(json["account"]["email"]).to eq("user@example.com")
    end

    it "allows login with uppercase email" do
      post "/api/v1/auth/login", params: {
        email: "USER@EXAMPLE.COM",
        password: "correct_password"
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["jwt"]).to be_present
      expect(json["account"]["email"]).to eq("user@example.com")
    end

    it "allows login with email containing whitespace" do
      post "/api/v1/auth/login", params: {
        email: "  user@example.com  ",
        password: "correct_password"
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["jwt"]).to be_present
    end
  end

  describe "異常系: 認証失敗" do
    let!(:account) { create_test_account(email: "user@example.com", password: "correct_password") }

    it "returns error for invalid password" do
      post "/api/v1/auth/login", params: {
        email: "user@example.com",
        password: "wrong_password"
      }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)

      expect(json["error"]).to be_present
      expect(json["error"]["code"]).to eq("LOGIN_FAILED")
      expect(json["error"]["message"]).to eq("Invalid email or password")
      expect(json["error"]["trace_id"]).to be_present
    end

    it "returns error for non-existent email" do
      post "/api/v1/auth/login", params: {
        email: "nonexistent@example.com",
        password: "password123"
      }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)

      expect(json["error"]["code"]).to eq("LOGIN_FAILED")
      expect(json["error"]["message"]).to eq("Invalid email or password")
    end

    it "does not reveal account existence (same error for both cases)" do
      # 実在するアカウントへの誤パスワード
      post "/api/v1/auth/login", params: {
        email: "user@example.com",
        password: "wrong_password"
      }
      existing_response = JSON.parse(response.body)

      # 実在しないアカウント
      post "/api/v1/auth/login", params: {
        email: "nonexistent@example.com",
        password: "password123"
      }
      nonexistent_response = JSON.parse(response.body)

      # エラーメッセージが同一であることを確認（セキュリティ対策）
      expect(existing_response["error"]["message"])
        .to eq(nonexistent_response["error"]["message"])
    end
  end

  describe "異常系: パラメータ不足" do
    let!(:account) { create_test_account(email: "user@example.com", password: "correct_password") }

    it "returns error for missing email" do
      post "/api/v1/auth/login", params: {
        password: "correct_password"
      }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)

      expect(json["error"]["code"]).to eq("LOGIN_FAILED")
    end

    it "returns error for missing password" do
      post "/api/v1/auth/login", params: {
        email: "user@example.com"
      }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)

      expect(json["error"]["code"]).to eq("LOGIN_FAILED")
    end

    it "returns error for empty email" do
      post "/api/v1/auth/login", params: {
        email: "",
        password: "correct_password"
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns error for empty password" do
      post "/api/v1/auth/login", params: {
        email: "user@example.com",
        password: ""
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "異常系: アカウントステータス" do
    it "allows login for locked accounts (status checks skipped)" do
      account = create_test_account(email: "locked@example.com", password: "password123")
      account.update!(status: "locked")

      post "/api/v1/auth/login", params: {
        email: "locked@example.com",
        password: "password123"
      }

      # skip_status_checks? が有効なため、ログイン成功
      expect(response).to have_http_status(:ok)
    end

    it "allows login for unverified accounts (status checks skipped)" do
      account = create_test_account(email: "unverified@example.com", password: "password123")
      account.update!(status: "unverified")

      post "/api/v1/auth/login", params: {
        email: "unverified@example.com",
        password: "password123"
      }

      # skip_status_checks? が有効なため、ログイン成功
      expect(response).to have_http_status(:ok)
    end
  end

  describe "レスポンス形式の検証" do
    let!(:account) { create_test_account(email: "user@example.com", password: "correct_password") }

    it "returns expected JSON structure on success" do
      post "/api/v1/auth/login", params: {
        email: "user@example.com",
        password: "correct_password"
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # 必須フィールドの存在を確認
      expect(json.keys).to contain_exactly("jwt", "account")
      expect(json["account"].keys).to contain_exactly("id", "email", "status")

      # 型の確認
      expect(json["jwt"]).to be_a(String)
      expect(json["account"]["id"]).to be_an(Integer)
      expect(json["account"]["email"]).to be_a(String)
      expect(json["account"]["status"]).to be_a(String)
    end

    it "returns expected JSON structure on error" do
      post "/api/v1/auth/login", params: {
        email: "user@example.com",
        password: "wrong_password"
      }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)

      # エラーレスポンス形式を確認
      expect(json.keys).to contain_exactly("error")
      expect(json["error"].keys).to contain_exactly("code", "message", "trace_id")

      # 型の確認
      expect(json["error"]["code"]).to be_a(String)
      expect(json["error"]["message"]).to be_a(String)
      expect(json["error"]["trace_id"]).to be_a(String)
    end
  end

  describe "JWT検証" do
    let!(:account) { create_test_account(email: "user@example.com", password: "correct_password") }

    it "generates valid JWT that can be decoded" do
      post "/api/v1/auth/login", params: {
        email: "user@example.com",
        password: "correct_password"
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      jwt = json["jwt"]

      # JWTServiceでデコードできることを確認
      payload = Authentication::JwtService.decode(jwt)
      expect(payload).to be_present
    end

    it "JWT contains account_id in payload" do
      post "/api/v1/auth/login", params: {
        email: "user@example.com",
        password: "correct_password"
      }

      json = JSON.parse(response.body)
      jwt = json["jwt"]

      payload = Authentication::JwtService.decode(jwt)
      expect(payload["account_id"]).to eq(account.id)
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength, RSpec/LetSetup
