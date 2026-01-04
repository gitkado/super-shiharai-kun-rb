# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe "POST /api/v1/auth/register", type: :request do
  describe "正常系: ユーザー登録とJWT発行" do
    it "アカウントを作成し、JWTとアカウント情報を返す" do
      post "/api/v1/auth/register", params: {
        email: "newuser@example.com",
        password: "secure_password123"
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)

      # JWTが発行されることを確認
      expect(json["jwt"]).to be_present
      expect(json["jwt"]).to be_a(String)

      # アカウント情報が返却されることを確認
      expect(json["account"]).to be_present
      expect(json["account"]["id"]).to be_present
      expect(json["account"]["email"]).to eq("newuser@example.com")
      expect(json["account"]["status"]).to eq("verified")

      # データベースにアカウントが作成されることを確認
      account = Account.find_by(email: "newuser@example.com")
      expect(account).to be_present
      expect(account.status).to eq("verified")

      # パスワードハッシュが作成されることを確認
      password_hash = AccountPasswordHash.find_by(account_id: account.id)
      expect(password_hash).to be_present
      expect(password_hash.password_hash).to be_present
    end

    it "メールアドレスを小文字に正規化する" do
      post "/api/v1/auth/register", params: {
        email: "NEWUSER@EXAMPLE.COM",
        password: "secure_password123"
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)

      expect(json["account"]["email"]).to eq("newuser@example.com")
      expect(Account.find_by(email: "newuser@example.com")).to be_present
    end

    it "メールアドレスの前後空白を除去する" do
      post "/api/v1/auth/register", params: {
        email: "  newuser@example.com  ",
        password: "secure_password123"
      }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)

      expect(json["account"]["email"]).to eq("newuser@example.com")
    end
  end

  describe "異常系: メールアドレス重複" do
    it "重複するメールアドレスの場合にエラーを返す" do
      # 既存アカウント作成
      Account.create!(email: "existing@example.com", status: "verified")

      post "/api/v1/auth/register", params: {
        email: "existing@example.com",
        password: "password123"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["error"]).to be_present
      expect(json["error"]["code"]).to eq("REGISTRATION_FAILED")
      expect(json["error"]["message"]).to include("Email")
      expect(json["error"]["trace_id"]).to be_present
    end

    it "大文字小文字を区別せず重複チェックする" do
      Account.create!(email: "existing@example.com", status: "verified")

      post "/api/v1/auth/register", params: {
        email: "EXISTING@EXAMPLE.COM",
        password: "password123"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["error"]["code"]).to eq("REGISTRATION_FAILED")
    end
  end

  describe "異常系: 無効なメールアドレス" do
    it "不正なメールアドレス形式の場合にエラーを返す" do
      post "/api/v1/auth/register", params: {
        email: "invalid-email",
        password: "password123"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["error"]["code"]).to eq("REGISTRATION_FAILED")
      expect(json["error"]["message"]).to be_present
      expect(json["error"]["trace_id"]).to be_present
    end

    it "@がないメールアドレスの場合にエラーを返す" do
      post "/api/v1/auth/register", params: {
        email: "nodomain",
        password: "password123"
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "ドメインがないメールアドレスの場合にエラーを返す" do
      post "/api/v1/auth/register", params: {
        email: "user@",
        password: "password123"
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "メールアドレスが空の場合にエラーを返す" do
      post "/api/v1/auth/register", params: {
        email: "",
        password: "password123"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["error"]["code"]).to eq("REGISTRATION_FAILED")
    end
  end

  describe "異常系: パスワード不足" do
    it "パスワードが空の場合にエラーを返す" do
      post "/api/v1/auth/register", params: {
        email: "user@example.com",
        password: ""
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["error"]["code"]).to eq("REGISTRATION_FAILED")
      expect(json["error"]["message"]).to be_present
    end

    it "パスワードが未指定の場合にエラーを返す" do
      post "/api/v1/auth/register", params: {
        email: "user@example.com"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["error"]["code"]).to eq("REGISTRATION_FAILED")
    end
  end

  describe "レスポンス形式の検証" do
    it "期待されるJSON構造を返す" do
      post "/api/v1/auth/register", params: {
        email: "newuser@example.com",
        password: "secure_password123"
      }

      expect(response).to have_http_status(:created)
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
  end
end
# rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
