# frozen_string_literal: true

# NOTE: ルーティングとモジュール構造(&ファイルパス)を合わせることでRailsエコシステムの恩恵を最大限受ける
module Api
  module V1
    class InvoicesController < ApplicationController
      before_action :authenticate_account!

      # POST /api/v1/invoices
      def create
        # NOTE: user_idはcurrent_accountから取得するためパラメータとして受け取らない(セキュリティ対策)
        invoice = Invoice.new(invoice_params.merge(user_id: current_account.id))

        if invoice.save
          render json: invoice_json(invoice), status: :created
        else
          render json: {
            error: {
              code: "INVOICE_CREATION_FAILED",
              message: invoice.errors.full_messages.join(", "),
              trace_id: trace_id
            }
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/invoices
      def index
        invoices = Invoice.where(user_id: current_account.id)

        # NOTE: SQL WHERE句で絞り込むため効率的
        if params[:start_date].present?
          invoices = invoices.where("payment_due_date >= ?", Date.parse(params[:start_date]))
        end
        if params[:end_date].present?
          invoices = invoices.where("payment_due_date <= ?", Date.parse(params[:end_date]))
        end
        invoices = invoices.order(payment_due_date: :desc, created_at: :desc)

        render json: { invoices: invoices.map { |invoice| invoice_json(invoice) } }
      rescue Date::Error
        render json: {
          error: {
            code: "INVALID_DATE_FORMAT",
            message: "Invalid date format. Use YYYY-MM-DD.",
            trace_id: trace_id
          }
        }, status: :bad_request
      end

      private

      def invoice_params
        # NOTE: Strong Parametersを使用して許可されたパラメータのみを受け入れる
        params.permit(:issue_date, :payment_amount, :payment_due_date)
      end

      # TODO: 将来的にActiveModel::Serializerを導入してJSON生成を一元化することを検討
      def invoice_json(invoice)
        {
          id: invoice.id,
          user_id: invoice.user_id,
          issue_date: invoice.issue_date.to_s,
          payment_amount: invoice.payment_amount.to_s,
          fee: invoice.fee.to_s,
          fee_rate: invoice.fee_rate.to_s,
          tax_amount: invoice.tax_amount.to_s,
          tax_rate: invoice.tax_rate.to_s,
          total_amount: invoice.total_amount.to_s,
          payment_due_date: invoice.payment_due_date.to_s,
          created_at: invoice.created_at.iso8601,
          updated_at: invoice.updated_at.iso8601
        }
      end

      def trace_id
        SemanticLogger.named_tags[:trace_id]
      end
    end
  end
end
