# frozen_string_literal: true

require "uri"

class Account < ApplicationRecord
  # Rodauth標準のステータス値をEnumで定義
  # 文字列ベース（Rodauth互換性のため）
  enum :status, {
    unverified: "unverified", # メール未確認
    verified: "verified",     # メール確認済み（デフォルト）
    locked: "locked",         # アカウントロック
    closed: "closed"          # アカウント閉鎖
  }, prefix: true

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }

  before_validation :normalize_email

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
