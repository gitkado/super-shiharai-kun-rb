# frozen_string_literal: true

# エラーハンドリングの共通処理を提供するconcern
# 全てのコントローラーで発生する可能性のあるエラーを捕捉し、
# 統一されたJSON形式でレスポンスを返す
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from DomainError, with: :domain_error
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request
    rescue_from StandardError, with: :internal_server_error
  end

  private

  # ドメインエラー（ビジネスロジック由来のエラー）
  def domain_error(exception)
    render_error(
      status: exception.status,
      code: exception.code,
      message: exception.message
    )
  end

  # リソースが見つからない場合
  def record_not_found(exception)
    render_error(
      status: :not_found,
      code: "RESOURCE_NOT_FOUND",
      message: exception.message
    )
  end

  # バリデーションエラー
  def unprocessable_entity(exception)
    render_error(
      status: :unprocessable_entity,
      code: "VALIDATION_ERROR",
      message: exception.message,
      details: exception.record&.errors&.full_messages
    )
  end

  # 必須パラメータ不足
  def bad_request(exception)
    render_error(
      status: :bad_request,
      code: "BAD_REQUEST",
      message: exception.message
    )
  end

  # 予期しないエラー
  def internal_server_error(exception)
    # 本番環境ではSentryやBugsnag等のエラー通知サービスに送信することを推奨
    Rails.logger.error("Internal Server Error: #{exception.class} - #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    render_error(
      status: :internal_server_error,
      code: "INTERNAL_SERVER_ERROR",
      message: "An unexpected error occurred"
    )
  end

  # エラーレスポンスの共通フォーマット
  def render_error(status:, code:, message:, details: nil)
    payload = {
      error: {
        code: code,
        message: message,
        trace_id: request.headers["X-Trace-Id"] || request.request_id
      }
    }
    payload[:error][:details] = details if details.present?

    render json: payload, status: status
  end
end
