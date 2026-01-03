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
  # after_initialize: インスタンス生成直後に手数料・税額を計算（常に完全な状態を保証）
  after_initialize :ensure_calculated_fields
  # before_validation: save前の最終チェックとして再計算（新規・更新両方）
  before_validation :recalculate_derived_fields, if: -> { payment_amount.present? }

  # FIXME: 計算が必要なカラムは計算メソッドにまとめて整合性を保つために常に監視しないでも良くする
  # セッターオーバーライド: 計算元の属性が変更されたら即座に再計算
  %i[payment_amount fee_rate tax_rate].each do |attr|
    define_method("#{attr}=") do |value|
      super(value)  # ActiveRecordの元のセッターを呼ぶ
      recalculate_derived_fields if persisted? && payment_amount  # 既存レコードのみ即座に再計算
    end
  end

  # スコープ
  scope :between_payment_due_dates, ->(start_date, end_date) {
    where(payment_due_date: start_date..end_date)
  }

  private

  # after_initialize: インスタンス生成時の初期計算
  # - 新規レコード: デフォルトのfee_rate/tax_rateを設定して計算
  # - 既存レコード: DBから読み込んだ値で計算（整合性確認）
  def ensure_calculated_fields
    return unless payment_amount

    # デフォルト値を設定（新規作成時のみ）
    self.fee_rate ||= Invoice::Rate.new(AppConfig.invoice_fee_rate)
    self.tax_rate ||= Invoice::Rate.new(AppConfig.invoice_tax_rate)

    recalculate_derived_fields
  end

  # 派生値を再計算（セッター経由での変更時に即座に呼ばれる）
  def recalculate_derived_fields
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
