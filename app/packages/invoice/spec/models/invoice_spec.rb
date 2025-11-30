# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invoice, type: :model do
  # テスト用のアカウント作成
  let(:account) { Account.create!(email: "test@example.com", status: "verified") }

  describe "バリデーション" do
    it "user_idの存在を検証すること" do
      invoice = described_class.new(
        issue_date: Date.today,
        payment_amount: Invoice::Money.new(100000),
        payment_due_date: Date.today + 30.days
      )
      expect(invoice.valid?).to be(false)
      expect(invoice.errors[:account]).to include("must exist")
    end

    it "issue_dateの存在を検証すること" do
      invoice = described_class.new(
        user_id: account.id,
        payment_amount: Invoice::Money.new(100000),
        payment_due_date: Date.today + 30.days
      )
      expect(invoice.valid?).to be(false)
      expect(invoice.errors[:issue_date]).to include("can't be blank")
    end

    it "payment_amountの存在を検証すること" do
      invoice = described_class.new(
        user_id: account.id,
        issue_date: Date.today,
        payment_due_date: Date.today + 30.days
      )
      expect(invoice.valid?).to be(false)
      expect(invoice.errors[:payment_amount]).to include("can't be blank")
    end

    it "payment_due_dateの存在を検証すること" do
      invoice = described_class.new(
        user_id: account.id,
        issue_date: Date.today,
        payment_amount: Invoice::Money.new(100000)
      )
      expect(invoice.valid?).to be(false)
      expect(invoice.errors[:payment_due_date]).to include("can't be blank")
    end

    context "payment_due_dateのバリデーション" do
      it "issue_date以降のpayment_due_dateを受け入れること" do
        invoice = described_class.new(
          user_id: account.id,
          issue_date: Date.today,
          payment_amount: Invoice::Money.new(100000),
          payment_due_date: Date.today
        )
        expect(invoice.valid?).to be(true)
      end

      it "issue_date以前のpayment_due_dateを拒否すること" do
        invoice = described_class.new(
          user_id: account.id,
          issue_date: Date.today,
          payment_amount: Invoice::Money.new(100000),
          payment_due_date: Date.today - 1.day
        )
        expect(invoice.valid?).to be(false)
        expect(invoice.errors[:payment_due_date]).to include("must be on or after issue_date")
      end
    end

    context "payment_amountのバリデーション" do
      it "正の値のpayment_amountを受け入れること" do
        invoice = described_class.new(
          user_id: account.id,
          issue_date: Date.today,
          payment_amount: Invoice::Money.new(1),
          payment_due_date: Date.today + 30.days
        )
        expect(invoice.valid?).to be(true)
      end

      it "ゼロのpayment_amountを拒否すること" do
        invoice = described_class.new(
          user_id: account.id,
          issue_date: Date.today,
          payment_amount: Invoice::Money.new(0),
          payment_due_date: Date.today + 30.days
        )
        expect(invoice.valid?).to be(false)
        expect(invoice.errors[:payment_amount]).to include("must be greater than 0")
      end

      it "負の値のpayment_amountを拒否すること" do
        invoice = described_class.new(
          user_id: account.id,
          issue_date: Date.today,
          payment_amount: Invoice::Money.new(-100),
          payment_due_date: Date.today + 30.days
        )
        expect(invoice.valid?).to be(false)
      end
    end
  end

  describe "#calculate_fees_and_taxes" do
    it "デフォルト料率で手数料を計算すること" do
      invoice = described_class.create!(
        user_id: account.id,
        issue_date: Date.today,
        payment_amount: Invoice::Money.new(100000),
        payment_due_date: Date.today + 30.days
      )

      # fee = 100000 × 0.04 = 4000
      expect(invoice.fee.value).to eq(BigDecimal("4000.00"))
      # tax_amount = 4000 × 0.10 = 400
      expect(invoice.tax_amount.value).to eq(BigDecimal("400.00"))
      # total_amount = 100000 + 4000 + 400 = 104400
      expect(invoice.total_amount.value).to eq(BigDecimal("104400.00"))

      # 料率も保存される
      expect(invoice.fee_rate.value).to eq(BigDecimal("0.0400"))
      expect(invoice.tax_rate.value).to eq(BigDecimal("0.1000"))
    end

    it "カスタム料率で手数料を計算すること" do
      original_fee_rate = ENV["INVOICE_FEE_RATE"]
      original_tax_rate = ENV["INVOICE_TAX_RATE"]

      begin
        # 環境変数を一時的に上書き
        ENV["INVOICE_FEE_RATE"] = "0.05"
        ENV["INVOICE_TAX_RATE"] = "0.08"

        invoice = described_class.create!(
          user_id: account.id,
          issue_date: Date.today,
          payment_amount: Invoice::Money.new(100000),
          payment_due_date: Date.today + 30.days
        )

        # fee = 100000 × 0.05 = 5000
        expect(invoice.fee.value).to eq(BigDecimal("5000.00"))
        # tax_amount = 5000 × 0.08 = 400
        expect(invoice.tax_amount.value).to eq(BigDecimal("400.00"))
        # total_amount = 100000 + 5000 + 400 = 105400
        expect(invoice.total_amount.value).to eq(BigDecimal("105400.00"))
      ensure
        # 環境変数を元の値に復元
        ENV["INVOICE_FEE_RATE"] = original_fee_rate
        ENV["INVOICE_TAX_RATE"] = original_tax_rate
      end
    end

    it "丸め処理を正しく行うこと" do
      invoice = described_class.create!(
        user_id: account.id,
        issue_date: Date.today,
        payment_amount: Invoice::Money.new("100000.33"),
        payment_due_date: Date.today + 30.days
      )

      # fee = 100000.33 × 0.04 = 4000.0132 → 4000.01
      expect(invoice.fee.value).to eq(BigDecimal("4000.01"))
      # tax_amount = 4000.01 × 0.10 = 400.001 → 400.00
      expect(invoice.tax_amount.value).to eq(BigDecimal("400.00"))
      # total_amount = 100000.33 + 4000.01 + 400.00 = 104400.34
      expect(invoice.total_amount.value).to eq(BigDecimal("104400.34"))
    end
  end

  describe ".between_payment_due_dates" do
    before do
      # テストデータ作成（未来の日付を使用）
      base_date = Date.today + 30.days
      described_class.create!(
        user_id: account.id,
        issue_date: Date.today,
        payment_amount: Invoice::Money.new(100000),
        payment_due_date: base_date
      )
      described_class.create!(
        user_id: account.id,
        issue_date: Date.today,
        payment_amount: Invoice::Money.new(200000),
        payment_due_date: base_date + 16.days
      )
      described_class.create!(
        user_id: account.id,
        issue_date: Date.today,
        payment_amount: Invoice::Money.new(300000),
        payment_due_date: base_date + 46.days
      )
    end

    it "日付範囲内の請求書を返すこと" do
      base_date = Date.today + 30.days
      invoices = described_class.between_payment_due_dates(base_date, base_date + 16.days)
      expect(invoices.count).to eq(2)
    end

    it "境界日付を含むこと" do
      base_date = Date.today + 30.days
      invoices = described_class.between_payment_due_dates(base_date, base_date)
      expect(invoices.count).to eq(1)
    end

    it "一致がない場合は空の配列を返すこと" do
      future_date = Date.today + 200.days
      invoices = described_class.between_payment_due_dates(future_date, future_date + 30.days)
      expect(invoices.count).to eq(0)
    end
  end
end
