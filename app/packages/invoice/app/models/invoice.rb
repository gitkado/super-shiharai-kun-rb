# frozen_string_literal: true

# 請求書モデル
# 責務: 請求書データの永続化・バリデーション、手数料・税額・合計金額の自動計算
class Invoice < ApplicationRecord
  # ActiveRecord Attributes（値オブジェクト）
  attribute :payment_amount, Invoice::Money::Type.new
  attribute :fee, Invoice::Money::Type.new
  attribute :fee_rate, Invoice::Rate::Type.new
  attribute :tax_amount, Invoice::Money::Type.new
  attribute :tax_rate, Invoice::Rate::Type.new
  attribute :total_amount, Invoice::Money::Type.new

  # 関連
  belongs_to :account, class_name: "Account", foreign_key: :user_id, optional: false

  # バリデーション
  validates :issue_date, presence: true
  validates :payment_amount, presence: true
  validates :payment_due_date, presence: true
  validate :payment_due_date_after_issue_date
  validate :payment_amount_positive

  # コールバック
  before_validation :calculate_fees_and_taxes, if: :needs_recalculation?

  # スコープ
  scope :between_payment_due_dates, ->(start_date, end_date) {
    where(payment_due_date: start_date..end_date)
  }

  private

  # 再計算が必要かどうかを判定
  def needs_recalculation?
    payment_amount_changed? || fee_rate_changed? || tax_rate_changed? || new_record?
  end

  def calculate_fees_and_taxes
    return unless payment_amount

    self.fee_rate ||= Invoice::Rate.new(AppConfig.invoice_fee_rate)
    self.tax_rate ||= Invoice::Rate.new(AppConfig.invoice_tax_rate)

    self.fee = payment_amount * fee_rate.value
    self.tax_amount = fee * tax_rate.value
    self.total_amount = payment_amount + fee + tax_amount
  end

  def payment_due_date_after_issue_date
    return unless issue_date && payment_due_date

    if payment_due_date < issue_date
      errors.add(:payment_due_date, "must be on or after issue_date")
    end
  end

  def payment_amount_positive
    return unless payment_amount

    if payment_amount.value <= 0
      errors.add(:payment_amount, "must be greater than 0")
    end
  end
end
