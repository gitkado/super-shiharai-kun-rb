# frozen_string_literal: true

require "swagger_helper"

# rubocop:disable RSpec/LetSetup
RSpec.describe "Authentication API", type: :request do
  path "/api/v1/auth/register" do
    post "\u30E6\u30FC\u30B6\u30FC\u767B\u9332" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      description "\u30A2\u30AB\u30A6\u30F3\u30C8\u3092\u4F5C\u6210\u3057\u3001JWT\u30C8\u30FC\u30AF\u30F3\u3092\u767A\u884C\u3057\u307E\u3059"

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: {
            type: :string,
            format: :email,
            description: "\u30E1\u30FC\u30EB\u30A2\u30C9\u30EC\u30B9\uFF08\u4E00\u610F\uFF09",
            example: "user@example.com"
          },
          password: {
            type: :string,
            format: :password,
            description: "\u30D1\u30B9\u30EF\u30FC\u30C9",
            example: "secure_password_123"
          }
        },
        required: %w[email password]
      }

      response "201", "\u30A2\u30AB\u30A6\u30F3\u30C8\u4F5C\u6210\u6210\u529F" do
        schema type: :object,
               properties: {
                 jwt: {
                   type: :string,
                   description: "JWT\u30C8\u30FC\u30AF\u30F3\uFF08\u8A8D\u8A3C\u7528\uFF09",
                   example: "eyJhbGciOiJIUzI1NiJ9.eyJhY2NvdW50X2lkIjoxLCJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJleHAiOjE3MzAwMDAwMDB9.abc123"
                 },
                 account: {
                   type: :object,
                   properties: {
                     id: { type: :integer, example: 1 },
                     email: { type: :string, example: "user@example.com" },
                     status: { type: :string, example: "verified", enum: %w[unverified verified locked closed] }
                   },
                   required: %w[id email status]
                 }
               },
               required: %w[jwt account]

        let(:credentials) { { email: "newuser@example.com", password: "password123" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["jwt"]).to be_present
          expect(data["account"]["email"]).to eq("newuser@example.com")
          expect(data["account"]["status"]).to eq("verified")
        end
      end

      response "422", "\u30D0\u30EA\u30C7\u30FC\u30B7\u30E7\u30F3\u30A8\u30E9\u30FC\uFF08\u30E1\u30FC\u30EB\u91CD\u8907\u306A\u3069\uFF09" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        let!(:existing_account) { Account.create!(email: "duplicate@example.com", status: "verified") }
        let(:credentials) { { email: "duplicate@example.com", password: "password123" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("REGISTRATION_FAILED")
          expect(data["error"]["trace_id"]).to be_present
        end
      end

      response "422", "\u30D1\u30E9\u30E1\u30FC\u30BF\u4E0D\u8DB3\u30A8\u30E9\u30FC" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        let(:credentials) { { email: "test@example.com" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("REGISTRATION_FAILED")
        end
      end
    end
  end

  path "/api/v1/auth/login" do
    post "\u30ED\u30B0\u30A4\u30F3" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      description "\u30E1\u30FC\u30EB\u30A2\u30C9\u30EC\u30B9\u3068\u30D1\u30B9\u30EF\u30FC\u30C9\u3067\u8A8D\u8A3C\u3057\u3001JWT\u30C8\u30FC\u30AF\u30F3\u3092\u767A\u884C\u3057\u307E\u3059"

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: {
            type: :string,
            format: :email,
            description: "\u30E1\u30FC\u30EB\u30A2\u30C9\u30EC\u30B9",
            example: "user@example.com"
          },
          password: {
            type: :string,
            format: :password,
            description: "\u30D1\u30B9\u30EF\u30FC\u30C9",
            example: "secure_password_123"
          }
        },
        required: %w[email password]
      }

      response "200", "\u30ED\u30B0\u30A4\u30F3\u6210\u529F" do
        schema type: :object,
               properties: {
                 jwt: {
                   type: :string,
                   description: "JWT\u30C8\u30FC\u30AF\u30F3\uFF08\u8A8D\u8A3C\u7528\uFF09",
                   example: "eyJhbGciOiJIUzI1NiJ9.eyJhY2NvdW50X2lkIjoxLCJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJleHAiOjE3MzAwMDAwMDB9.abc123"
                 },
                 account: {
                   type: :object,
                   properties: {
                     id: { type: :integer, example: 1 },
                     email: { type: :string, example: "user@example.com" },
                     status: { type: :string, example: "verified", enum: %w[unverified verified locked closed] }
                   },
                   required: %w[id email status]
                 }
               },
               required: %w[jwt account]

        # テストデータ準備
        let!(:test_account) do
          account = Account.create!(email: "logintest@example.com", status: "verified")
          password_hash = BCrypt::Password.create("correct_password", cost: BCrypt::Engine::MIN_COST)
          AccountPasswordHash.create!(account_id: account.id, password_hash: password_hash)
          account
        end

        let(:credentials) { { email: "logintest@example.com", password: "correct_password" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["jwt"]).to be_present
          expect(data["account"]["email"]).to eq("logintest@example.com")
          expect(data["account"]["status"]).to eq("verified")
        end
      end

      response "401", "\u8A8D\u8A3C\u5931\u6557\uFF08\u30E1\u30FC\u30EB\u30A2\u30C9\u30EC\u30B9\u307E\u305F\u306F\u30D1\u30B9\u30EF\u30FC\u30C9\u304C\u4E0D\u6B63\uFF09" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        let!(:test_account) do
          account = Account.create!(email: "logintest@example.com", status: "verified")
          password_hash = BCrypt::Password.create("correct_password", cost: BCrypt::Engine::MIN_COST)
          AccountPasswordHash.create!(account_id: account.id, password_hash: password_hash)
          account
        end

        let(:credentials) { { email: "logintest@example.com", password: "wrong_password" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("LOGIN_FAILED")
          expect(data["error"]["message"]).to eq("Invalid email or password")
          expect(data["error"]["trace_id"]).to be_present
        end
      end

      response "401", "\u30D1\u30E9\u30E1\u30FC\u30BF\u4E0D\u8DB3\u30A8\u30E9\u30FC" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        let(:credentials) { { email: "test@example.com" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("LOGIN_FAILED")
        end
      end
    end
  end
end
# rubocop:enable RSpec/LetSetup
