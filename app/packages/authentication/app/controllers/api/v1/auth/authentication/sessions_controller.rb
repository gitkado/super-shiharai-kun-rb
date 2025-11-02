# frozen_string_literal: true

# ログインコントローラー（薄いラッパー）
# 責務: ログイン認証とエラーハンドリング・レスポンス整形
module Api
  module V1
    module Auth
      module Authentication
        class SessionsController < ApplicationController
          # POST /api/v1/auth/login
          # ログイン認証とJWT発行
          def create
            # アカウント存在確認（正規化されたemailで検索）
            normalized_email = params[:email]&.downcase&.strip
            account = Account.find_by(email: normalized_email)

            unless account
              return render json: {
                error: {
                  code: "LOGIN_FAILED",
                  message: "Invalid email or password",
                  trace_id: trace_id
                }
              }, status: :unauthorized
            end

            # パスワード検証
            password_hash_record = AccountPasswordHash.find_by(account_id: account.id)

            if password_hash_record && authenticate_password(params[:password], password_hash_record.password_hash)
              # JWT発行
              jwt = ::Authentication::JwtService.generate(account)

              render json: {
                jwt: jwt,
                account: { id: account.id, email: account.email, status: account.status }
              }, status: :ok
            else
              render json: {
                error: {
                  code: "LOGIN_FAILED",
                  message: "Invalid email or password",
                  trace_id: trace_id
                }
              }, status: :unauthorized
            end
          rescue StandardError => e
            render json: {
              error: {
                code: "LOGIN_FAILED",
                message: "Invalid email or password",
                trace_id: trace_id
              }
            }, status: :unauthorized
          end

          private

          # パスワード認証
          def authenticate_password(raw_password, hashed_password)
            return false if raw_password.blank? || hashed_password.blank?

            BCrypt::Password.new(hashed_password) == raw_password
          rescue BCrypt::Errors::InvalidHash
            false
          end

          # トレースIDを取得
          def trace_id
            SemanticLogger.named_tags[:trace_id]
          end
        end
      end
    end
  end
end
