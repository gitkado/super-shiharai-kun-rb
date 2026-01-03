# frozen_string_literal: true

module Authentication
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      attr_reader :current_account
    end

    # private以下で定義したメソッドはincluding先クラスのprivateインスタンスメソッドになる
    private

    def authenticate_account!
      token = extract_token_from_header

      return unauthorized_response unless token

      payload = Authentication::JwtService.decode(token)
      return unauthorized_response unless payload

      @current_account = Account.find_by(id: payload["account_id"])

      unauthorized_response unless @current_account
    end

    def extract_token_from_header
      header = request.headers["Authorization"]
      header&.split(" ")&.last if header&.start_with?("Bearer ")
    end

    def unauthorized_response
      render json: {
        error: {
          code: "UNAUTHORIZED",
          message: "Invalid or expired token",
          trace_id: SemanticLogger.named_tags[:trace_id]
        }
      }, status: :unauthorized

      false  # before_actionチェーンを停止
    end
  end
end
