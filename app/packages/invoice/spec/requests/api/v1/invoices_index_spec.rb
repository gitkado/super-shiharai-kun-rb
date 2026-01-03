# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/invoices", type: :request do
  let(:account) { Account.create!(email: "test@example.com", status: "verified") }
  let(:other_account) { Account.create!(email: "other@example.com", status: "verified") }
  let(:jwt) { Authentication::JwtService.generate(account) }
  let(:headers) { { "Authorization" => "Bearer #{jwt}" } }

  before do
    # テストデータ作成
    Invoice.create!(
      user_id: account.id,
      issue_date: Date.new(2025, 1, 1),
      payment_amount: Invoice::Money.new(100000),
      payment_due_date: Date.new(2025, 1, 15)
    )
    Invoice.create!(
      user_id: account.id,
      issue_date: Date.new(2025, 1, 1),
      payment_amount: Invoice::Money.new(200000),
      payment_due_date: Date.new(2025, 1, 31)
    )
    # 他ユーザーの請求書
    Invoice.create!(
      user_id: other_account.id,
      issue_date: Date.new(2025, 1, 1),
      payment_amount: Invoice::Money.new(300000),
      payment_due_date: Date.new(2025, 1, 15)
    )
  end

  describe "正常系" do
    it "returns all invoices for current user" do
      get "/api/v1/invoices", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(2)
      expect(json["invoices"].all? { |i| i["user_id"] == account.id }).to be(true)
    end

    it "filters by payment_due_date range" do
      get "/api/v1/invoices", params: {
        start_date: "2025-01-01",
        end_date: "2025-01-31"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(2)
    end

    it "filters by start_date only" do
      get "/api/v1/invoices", params: {
        start_date: "2025-01-20"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(1)
      expect(json["invoices"].first["payment_due_date"]).to eq("2025-01-31")
    end

    it "filters by end_date only" do
      get "/api/v1/invoices", params: {
        end_date: "2025-01-20"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(1)
      expect(json["invoices"].first["payment_due_date"]).to eq("2025-01-15")
    end

    it "returns empty array when no invoices match" do
      get "/api/v1/invoices", params: {
        start_date: "2025-03-01",
        end_date: "2025-03-31"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"]).to eq([])
    end

    it "returns invoices with all required fields" do
      get "/api/v1/invoices", headers: headers

      json = JSON.parse(response.body)
      invoice = json["invoices"].first

      expect(invoice).to have_key("id")
      expect(invoice).to have_key("user_id")
      expect(invoice).to have_key("issue_date")
      expect(invoice).to have_key("payment_amount")
      expect(invoice).to have_key("fee")
      expect(invoice).to have_key("fee_rate")
      expect(invoice).to have_key("tax_amount")
      expect(invoice).to have_key("tax_rate")
      expect(invoice).to have_key("total_amount")
      expect(invoice).to have_key("payment_due_date")
      expect(invoice).to have_key("created_at")
      expect(invoice).to have_key("updated_at")
    end

    it "returns invoices ordered by payment_due_date DESC, created_at DESC" do
      get "/api/v1/invoices", headers: headers

      json = JSON.parse(response.body)
      payment_due_dates = json["invoices"].map { |i| i["payment_due_date"] }

      # 支払期限が降順であることを確認
      expect(payment_due_dates).to eq(payment_due_dates.sort.reverse)
    end

    it "orders by created_at DESC when payment_due_date is the same" do
      # 同一支払期限の請求書を時間差で作成
      first_invoice = Invoice.create!(
        user_id: account.id,
        issue_date: Date.new(2025, 2, 1),
        payment_amount: Invoice::Money.new(50000),
        payment_due_date: Date.new(2025, 2, 28)
      )
      sleep 0.01 # created_at を確実に異なる値にする
      second_invoice = Invoice.create!(
        user_id: account.id,
        issue_date: Date.new(2025, 2, 1),
        payment_amount: Invoice::Money.new(60000),
        payment_due_date: Date.new(2025, 2, 28)
      )

      get "/api/v1/invoices", params: {
        start_date: "2025-02-01",
        end_date: "2025-02-28"
      }, headers: headers

      json = JSON.parse(response.body)
      invoice_ids = json["invoices"].map { |i| i["id"] }

      # 同一支払期限の場合、新しく作成された順（created_at降順）
      expect(invoice_ids.first).to eq(second_invoice.id)
      expect(invoice_ids.last).to eq(first_invoice.id)
    end

    it "returns empty array when user has no invoices" do
      # 新しいアカウントを作成（請求書なし）
      new_account = Account.create!(email: "newacc@example.com", status: "verified")
      new_jwt = Authentication::JwtService.generate(new_account)
      new_headers = { "Authorization" => "Bearer #{new_jwt}" }

      get "/api/v1/invoices", headers: new_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"]).to eq([])
    end

    it "filters correctly when start_date and end_date are the same" do
      get "/api/v1/invoices", params: {
        start_date: "2025-01-15",
        end_date: "2025-01-15"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(1)
      expect(json["invoices"].first["payment_due_date"]).to eq("2025-01-15")
    end
  end

  describe "異常系" do
    it "returns 401 without JWT" do
      get "/api/v1/invoices"

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("UNAUTHORIZED")
    end

    it "returns 401 with invalid JWT" do
      get "/api/v1/invoices", headers: { "Authorization" => "Bearer invalid_token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns error for invalid date format" do
      get "/api/v1/invoices", params: {
        start_date: "invalid-date",
        end_date: "2025-01-31"
      }, headers: headers

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("INVALID_DATE_FORMAT")
      expect(json["error"]["message"]).to eq("Invalid date format. Use YYYY-MM-DD.")
    end

    it "returns error for invalid end_date format" do
      get "/api/v1/invoices", params: {
        start_date: "2025-01-01",
        end_date: "not-a-date"
      }, headers: headers

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("INVALID_DATE_FORMAT")
      expect(json["error"]["message"]).to eq("Invalid date format. Use YYYY-MM-DD.")
      expect(json["error"]).to have_key("trace_id")
    end

    it "accepts date format with slashes (Date.parse accepts multiple formats)" do
      # NOTE: Date.parseは"2025/01/01"形式も受け付けるため、これは正常系として動作する
      get "/api/v1/invoices", params: {
        start_date: "2025/01/01",
        end_date: "2025-01-31"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"]).to be_an(Array)
    end
  end

  describe "アクセス制御" do
    it "does not return other users' invoices" do
      get "/api/v1/invoices", headers: headers

      json = JSON.parse(response.body)
      user_ids = json["invoices"].map { |i| i["user_id"] }.uniq
      expect(user_ids).to eq([ account.id ])
    end

    it "returns only invoices belonging to the authenticated user" do
      get "/api/v1/invoices", headers: headers

      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(2)
      expect(json["invoices"].none? { |i| i["user_id"] == other_account.id }).to be(true)
    end
  end
end
