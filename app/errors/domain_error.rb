# frozen_string_literal: true

# ドメイン固有のビジネスロジックエラーの基底クラス
# 各パッケージでこのクラスを継承してカスタムエラーを定義できる
#
# 使用例:
#   module Payments
#     class InsufficientFundsError < DomainError
#       def initialize(message = "Insufficient funds")
#         super(message, code: "INSUFFICIENT_FUNDS", status: :unprocessable_entity)
#       end
#     end
#   end
#
#   raise Payments::InsufficientFundsError
class DomainError < StandardError
  attr_reader :code, :status

  # @param message [String] エラーメッセージ
  # @param code [String] エラーコード（クライアント向けの識別子）
  # @param status [Symbol] HTTPステータスコード
  def initialize(message, code: "DOMAIN_ERROR", status: :unprocessable_entity)
    super(message)
    @code = code
    @status = status
  end
end
