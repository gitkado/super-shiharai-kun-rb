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
    it "認証ユーザーの全請求書を返す" do
      get "/api/v1/invoices", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(2)
      expect(json["invoices"].all? { |i| i["user_id"] == account.id }).to be(true)
    end

    it "支払期限の期間で絞り込む" do
      get "/api/v1/invoices", params: {
        start_date: "2025-01-01",
        end_date: "2025-01-31"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(2)
    end

    it "start_dateのみで絞り込む" do
      get "/api/v1/invoices", params: {
        start_date: "2025-01-20"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(1)
      expect(json["invoices"].first["payment_due_date"]).to eq("2025-01-31")
    end

    it "end_dateのみで絞り込む" do
      get "/api/v1/invoices", params: {
        end_date: "2025-01-20"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(1)
      expect(json["invoices"].first["payment_due_date"]).to eq("2025-01-15")
    end

    it "該当する請求書がない場合は空配列を返す" do
      get "/api/v1/invoices", params: {
        start_date: "2025-03-01",
        end_date: "2025-03-31"
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"]).to eq([])
    end

    it "全ての必須フィールドを含む請求書を返す" do
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

    it "支払期限の降順、作成日時の降順で返す" do
      get "/api/v1/invoices", headers: headers

      json = JSON.parse(response.body)
      payment_due_dates = json["invoices"].map { |i| i["payment_due_date"] }

      # 支払期限が降順であることを確認
      expect(payment_due_dates).to eq(payment_due_dates.sort.reverse)
    end

    it "支払期限が同じ場合は作成日時の降順で返す" do
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

    it "請求書が存在しないユーザーは空配列を返す" do
      # 新しいアカウントを作成（請求書なし）
      new_account = Account.create!(email: "newacc@example.com", status: "verified")
      new_jwt = Authentication::JwtService.generate(new_account)
      new_headers = { "Authorization" => "Bearer #{new_jwt}" }

      get "/api/v1/invoices", headers: new_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["invoices"]).to eq([])
    end

    it "start_dateとend_dateが同じ日付で正しく絞り込む" do
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
    it "JWT未提供時に401エラーを返す" do
      get "/api/v1/invoices"

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("UNAUTHORIZED")
    end

    it "無効なJWT時に401エラーを返す" do
      get "/api/v1/invoices", headers: { "Authorization" => "Bearer invalid_token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "不正な日付形式の場合にエラーを返す" do
      get "/api/v1/invoices", params: {
        start_date: "invalid-date",
        end_date: "2025-01-31"
      }, headers: headers

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("INVALID_DATE_FORMAT")
      expect(json["error"]["message"]).to eq("Invalid date format. Use YYYY-MM-DD.")
    end

    it "end_dateが不正な日付形式の場合にエラーを返す" do
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

    it "スラッシュ形式の日付も受け付ける（Date.parseの仕様）" do
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
    it "他ユーザーの請求書を含まない" do
      get "/api/v1/invoices", headers: headers

      json = JSON.parse(response.body)
      user_ids = json["invoices"].map { |i| i["user_id"] }.uniq
      expect(user_ids).to eq([ account.id ])
    end

    it "認証ユーザーの請求書のみを返す" do
      get "/api/v1/invoices", headers: headers

      json = JSON.parse(response.body)
      expect(json["invoices"].count).to eq(2)
      expect(json["invoices"].none? { |i| i["user_id"] == other_account.id }).to be(true)
    end
  end
end
