# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/invoices", type: :request do
  let(:account) { Account.create!(email: "test@example.com", status: "verified") }
  let(:jwt) { Authentication::JwtService.generate(account) }
  let(:headers) { { "Authorization" => "Bearer #{jwt}" } }

  describe "正常系" do
    it "請求書を作成し、手数料を自動計算して返す" do
      post "/api/v1/invoices", params: {
        issue_date: "2025-01-15",
        payment_amount: "100000",
        payment_due_date: "2025-02-28"
      }, headers: headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)

      expect(json["user_id"]).to eq(account.id)
      expect(json["payment_amount"]).to eq("100000.00")
      expect(json["fee"]).to eq("4000.00")
      expect(json["fee_rate"]).to eq("0.0400")
      expect(json["tax_amount"]).to eq("400.00")
      expect(json["tax_rate"]).to eq("0.1000")
      expect(json["total_amount"]).to eq("104400.00")
      expect(json["issue_date"]).to eq("2025-01-15")
      expect(json["payment_due_date"]).to eq("2025-02-28")
    end

    it "カスタム料率で手数料を計算する" do
      original_fee_rate = ENV["INVOICE_FEE_RATE"]
      original_tax_rate = ENV["INVOICE_TAX_RATE"]

      begin
        ENV["INVOICE_FEE_RATE"] = "0.05"
        ENV["INVOICE_TAX_RATE"] = "0.08"

        post "/api/v1/invoices", params: {
          issue_date: "2025-01-15",
          payment_amount: "100000",
          payment_due_date: "2025-02-28"
        }, headers: headers

        json = JSON.parse(response.body)
        expect(json["fee"]).to eq("5000.00")
        expect(json["tax_amount"]).to eq("400.00")
        expect(json["total_amount"]).to eq("105400.00")
      ensure
        ENV["INVOICE_FEE_RATE"] = original_fee_rate
        ENV["INVOICE_TAX_RATE"] = original_tax_rate
      end
    end
  end

  describe "異常系" do
    it "JWT未提供時に401エラーを返す" do
      post "/api/v1/invoices", params: {
        issue_date: "2025-01-15",
        payment_amount: "100000",
        payment_due_date: "2025-02-28"
      }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("UNAUTHORIZED")
    end

    it "無効なJWT時に401エラーを返す" do
      post "/api/v1/invoices", params: {
        issue_date: "2025-01-15",
        payment_amount: "100000",
        payment_due_date: "2025-02-28"
      }, headers: { "Authorization" => "Bearer invalid_token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "payment_amount未入力時にエラーを返す" do
      post "/api/v1/invoices", params: {
        issue_date: "2025-01-15",
        payment_due_date: "2025-02-28"
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("INVOICE_CREATION_FAILED")
    end

    it "payment_amountが負の値の場合にエラーを返す" do
      post "/api/v1/invoices", params: {
        issue_date: "2025-01-15",
        payment_amount: "-100",
        payment_due_date: "2025-02-28"
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]["message"]).to include("must be greater than 0")
    end

    it "payment_due_dateがissue_dateより前の場合にエラーを返す" do
      post "/api/v1/invoices", params: {
        issue_date: "2025-02-28",
        payment_amount: "100000",
        payment_due_date: "2025-01-15"
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]["message"]).to include("must be on or after issue_date")
    end
  end
end
