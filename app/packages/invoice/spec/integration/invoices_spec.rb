# frozen_string_literal: true

require "swagger_helper"

# rubocop:disable RSpec/LetSetup, RSpec/MultipleMemoizedHelpers, RSpec/VariableName
RSpec.describe "Invoices API", type: :request do
  # 共通のテストアカウントとJWT
  let!(:test_account) { Account.create!(email: "invoice_test@example.com", status: "verified") }
  let(:jwt) { Authentication::JwtService.generate(test_account) }
  let(:authorization_header) { "Bearer #{jwt}" }

  path "/api/v1/invoices" do
    post "請求書を登録する" do
      tags "Invoices"
      consumes "application/json"
      produces "application/json"
      description "請求書を登録し、手数料・税額を自動計算します"
      security [ bearer: [] ]

      parameter name: :Authorization, in: :header, type: :string, required: true,
                description: "Bearer <JWT>",
                example: "Bearer eyJhbGciOiJIUzI1NiJ9..."

      parameter name: :invoice, in: :body, schema: {
        type: :object,
        properties: {
          issue_date: {
            type: :string,
            format: :date,
            description: "請求日（YYYY-MM-DD形式）",
            example: "2025-01-15"
          },
          payment_amount: {
            type: :string,
            description: "支払金額（整数または小数、文字列形式）",
            example: "100000"
          },
          payment_due_date: {
            type: :string,
            format: :date,
            description: "支払期限（YYYY-MM-DD形式、issue_date以降）",
            example: "2025-02-28"
          }
        },
        required: %w[issue_date payment_amount payment_due_date]
      }

      response "201", "請求書作成成功" do
        schema type: :object,
               properties: {
                 id: { type: :integer, example: 1 },
                 user_id: { type: :integer, example: 1 },
                 issue_date: { type: :string, format: :date, example: "2025-01-15" },
                 payment_amount: { type: :string, example: "100000.00" },
                 fee: { type: :string, description: "手数料（自動計算）", example: "4000.00" },
                 fee_rate: { type: :string, description: "手数料率", example: "0.0400" },
                 tax_amount: { type: :string, description: "消費税額（自動計算）", example: "400.00" },
                 tax_rate: { type: :string, description: "消費税率", example: "0.1000" },
                 total_amount: { type: :string, description: "合計金額（payment_amount + fee + tax_amount）", example: "104400.00" },
                 payment_due_date: { type: :string, format: :date, example: "2025-02-28" },
                 created_at: { type: :string, format: "date-time", example: "2025-01-15T10:30:00Z" },
                 updated_at: { type: :string, format: "date-time", example: "2025-01-15T10:30:00Z" }
               },
               required: %w[id user_id issue_date payment_amount fee fee_rate tax_amount tax_rate total_amount payment_due_date created_at updated_at]

        let(:Authorization) { authorization_header }
        let(:invoice) do
          {
            issue_date: "2025-01-15",
            payment_amount: "100000",
            payment_due_date: "2025-02-28"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["user_id"]).to eq(test_account.id)
          expect(data["payment_amount"]).to eq("100000.00")
          expect(data["fee"]).to eq("4000.00")
          expect(data["total_amount"]).to eq("104400.00")
        end
      end

      response "401", "認証エラー（JWT未提供または無効）" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        let(:Authorization) { "Bearer invalid_token" }
        let(:invoice) do
          {
            issue_date: "2025-01-15",
            payment_amount: "100000",
            payment_due_date: "2025-02-28"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("UNAUTHORIZED")
          expect(data["error"]["trace_id"]).to be_present
        end
      end

      response "422", "バリデーションエラー（必須項目不足、不正な値など）" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        let(:Authorization) { authorization_header }
        let(:invoice) do
          {
            issue_date: "2025-01-15",
            payment_due_date: "2025-02-28"
            # payment_amount が欠落
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("INVOICE_CREATION_FAILED")
          expect(data["error"]["message"]).to be_present
          expect(data["error"]["trace_id"]).to be_present
        end
      end
    end

    get "請求書一覧を取得する" do
      tags "Invoices"
      produces "application/json"
      description "認証ユーザーの請求書一覧を取得します。支払期限での期間検索が可能です。"
      security [ bearer: [] ]

      parameter name: :Authorization, in: :header, type: :string, required: true,
                description: "Bearer <JWT>",
                example: "Bearer eyJhbGciOiJIUzI1NiJ9..."

      parameter name: :start_date, in: :query, type: :string, required: false,
                description: "支払期限の開始日（YYYY-MM-DD形式）",
                example: "2025-01-01"

      parameter name: :end_date, in: :query, type: :string, required: false,
                description: "支払期限の終了日（YYYY-MM-DD形式）",
                example: "2025-01-31"

      response "200", "一覧取得成功" do
        schema type: :object,
               properties: {
                 invoices: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer, example: 1 },
                       user_id: { type: :integer, example: 1 },
                       issue_date: { type: :string, format: :date, example: "2025-01-15" },
                       payment_amount: { type: :string, example: "100000.00" },
                       fee: { type: :string, example: "4000.00" },
                       fee_rate: { type: :string, example: "0.0400" },
                       tax_amount: { type: :string, example: "400.00" },
                       tax_rate: { type: :string, example: "0.1000" },
                       total_amount: { type: :string, example: "104400.00" },
                       payment_due_date: { type: :string, format: :date, example: "2025-02-28" },
                       created_at: { type: :string, format: "date-time", example: "2025-01-15T10:30:00Z" },
                       updated_at: { type: :string, format: "date-time", example: "2025-01-15T10:30:00Z" }
                     },
                     required: %w[id user_id issue_date payment_amount fee fee_rate tax_amount tax_rate total_amount payment_due_date created_at updated_at]
                   }
                 }
               },
               required: %w[invoices]

        let(:Authorization) { authorization_header }

        # テストデータ作成
        let!(:invoice1) do
          Invoice.create!(
            user_id: test_account.id,
            issue_date: Date.new(2025, 1, 1),
            payment_amount: Invoice::Money.new(100000),
            payment_due_date: Date.new(2025, 1, 31)
          )
        end

        let!(:invoice2) do
          Invoice.create!(
            user_id: test_account.id,
            issue_date: Date.new(2025, 1, 1),
            payment_amount: Invoice::Money.new(200000),
            payment_due_date: Date.new(2025, 2, 28)
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["invoices"]).to be_an(Array)
          expect(data["invoices"].count).to eq(2)
          expect(data["invoices"].all? { |i| i["user_id"] == test_account.id }).to be(true)
        end
      end

      response "200", "一覧取得成功（期間検索）" do
        schema type: :object,
               properties: {
                 invoices: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       user_id: { type: :integer },
                       issue_date: { type: :string, format: :date },
                       payment_amount: { type: :string },
                       fee: { type: :string },
                       fee_rate: { type: :string },
                       tax_amount: { type: :string },
                       tax_rate: { type: :string },
                       total_amount: { type: :string },
                       payment_due_date: { type: :string, format: :date },
                       created_at: { type: :string, format: "date-time" },
                       updated_at: { type: :string, format: "date-time" }
                     }
                   }
                 }
               }

        let(:Authorization) { authorization_header }
        let(:start_date) { "2025-01-01" }
        let(:end_date) { "2025-01-31" }

        # テストデータ作成
        let!(:invoice_in_range) do
          Invoice.create!(
            user_id: test_account.id,
            issue_date: Date.new(2025, 1, 1),
            payment_amount: Invoice::Money.new(100000),
            payment_due_date: Date.new(2025, 1, 15)
          )
        end

        let!(:invoice_out_of_range) do
          Invoice.create!(
            user_id: test_account.id,
            issue_date: Date.new(2025, 2, 1),
            payment_amount: Invoice::Money.new(200000),
            payment_due_date: Date.new(2025, 2, 28)
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["invoices"].count).to eq(1)
          expect(data["invoices"].first["payment_due_date"]).to eq("2025-01-15")
        end
      end

      response "401", "認証エラー（JWT未提供または無効）" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        let(:Authorization) { "Bearer invalid_token" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("UNAUTHORIZED")
        end
      end

      response "400", "不正な日付形式エラー" do
        schema "$ref" => "#/components/schemas/ErrorResponse"

        let(:Authorization) { authorization_header }
        let(:start_date) { "invalid-date" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("INVALID_DATE_FORMAT")
          expect(data["error"]["message"]).to eq("Invalid date format. Use YYYY-MM-DD.")
          expect(data["error"]["trace_id"]).to be_present
        end
      end
    end
  end
end
# rubocop:enable RSpec/LetSetup, RSpec/MultipleMemoizedHelpers, RSpec/VariableName
