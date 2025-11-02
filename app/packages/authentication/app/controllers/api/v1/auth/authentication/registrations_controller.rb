# frozen_string_literal: true

# ユーザー登録コントローラー（薄いラッパー）
# 責務: Rodauthのアカウント作成機能を呼び出し、エラーハンドリング・レスポンス整形のみ実施
module Api
  module V1
    module Auth
      module Authentication
        class RegistrationsController < ApplicationController
          # POST /api/v1/auth/register
          # ユーザー登録とJWT発行
          def create
            # アカウント作成
            account = Account.new(
              email: params[:email],
              status: "verified"
            )

            if account.valid? && params[:password].present?
              # トランザクション内でアカウントとパスワードハッシュを作成
              ActiveRecord::Base.transaction do
                account.save!

                # パスワードハッシュを作成（BCrypt）
                password_hash = BCrypt::Password.create(params[:password], cost: BCrypt::Engine::MIN_COST)
                AccountPasswordHash.create!(account_id: account.id, password_hash: password_hash)
              end

              # JWT発行
              jwt = ::Authentication::JwtService.generate(account)

              render json: {
                jwt: jwt,
                account: { id: account.id, email: account.email, status: account.status }
              }, status: :created
            else
              error_message = if params[:password].blank?
                "Password can't be blank"
              else
                account.errors.full_messages.join(", ")
              end

              render json: {
                error: {
                  code: "REGISTRATION_FAILED",
                  message: error_message,
                  trace_id: trace_id
                }
              }, status: :unprocessable_entity
            end
          rescue ActiveRecord::RecordInvalid => e
            render json: {
              error: {
                code: "REGISTRATION_FAILED",
                message: e.message,
                trace_id: trace_id
              }
            }, status: :unprocessable_entity
          rescue StandardError => e
            render json: {
              error: {
                code: "REGISTRATION_FAILED",
                message: e.message,
                trace_id: trace_id
              }
            }, status: :unprocessable_entity
          end

          private

          # トレースIDを取得
          def trace_id
            SemanticLogger.named_tags[:trace_id]
          end
        end
      end
    end
  end
end
