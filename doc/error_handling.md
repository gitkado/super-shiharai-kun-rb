# エラーハンドリング

このプロジェクトでは、Spring BootのGlobal Error Adviceに相当するグローバルなエラーハンドリングを実装しています。

## 概要

[ErrorHandling Concern](../app/controllers/concerns/error_handling.rb)を使用して、全てのコントローラーで発生する可能性のあるエラーを統一的に処理し、一貫したJSON形式でクライアントに返却します。

## アーキテクチャ

```
ApplicationController (基底クラス)
  ↓ include
ErrorHandling (Concern)
  ↓ rescue_from
各種例外 → 統一されたJSONレスポンス
```

## サポートされているエラー

| 例外クラス | HTTPステータス | エラーコード | 説明 |
|-----------|--------------|------------|------|
| `DomainError` | カスタマイズ可能 | カスタマイズ可能 | ビジネスロジック由来のエラー |
| `ActiveRecord::RecordNotFound` | 404 | `RESOURCE_NOT_FOUND` | リソースが見つからない |
| `ActiveRecord::RecordInvalid` | 422 | `VALIDATION_ERROR` | バリデーションエラー |
| `ActionController::ParameterMissing` | 400 | `BAD_REQUEST` | 必須パラメータ不足 |
| `StandardError` | 500 | `INTERNAL_SERVER_ERROR` | 予期しないエラー |

## エラーレスポンス形式

全てのエラーレスポンスは以下の形式で返却されます：

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーメッセージ",
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf",
    "details": ["詳細情報（オプション）"]
  }
}
```

### フィールド説明

- **code**: クライアント側で識別可能なエラーコード（大文字のスネークケース）
- **message**: 人間が読めるエラーメッセージ
- **trace_id**: リクエストを横断して追跡可能なトレースID（ログと紐付け可能）
- **details**: エラーの詳細情報（バリデーションエラー時など、オプション）

## 使用方法

### 1. 基本的な使い方

[ApplicationController](../app/controllers/application_controller.rb)に`ErrorHandling`がincludeされているため、全てのコントローラーで自動的にエラーハンドリングが有効になります。

```ruby
class UsersController < ApplicationController
  def show
    # RecordNotFoundが発生すると自動的に404レスポンスが返る
    user = User.find(params[:id])
    render json: user
  end
end
```

**レスポンス例（ユーザーが見つからない場合）:**

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Couldn't find User with 'id'=999",
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  }
}
```

### 2. バリデーションエラー

ActiveRecordのバリデーションエラーは自動的に処理されます。

```ruby
class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    user.save! # バリデーションエラーで RecordInvalid が発生
    render json: user, status: :created
  end
end
```

**レスポンス例:**

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed: Email can't be blank, Name is too short",
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf",
    "details": [
      "Email can't be blank",
      "Name is too short (minimum is 3 characters)"
    ]
  }
}
```

### 3. カスタムドメインエラー

ビジネスロジック固有のエラーは[DomainError](../app/errors/domain_error.rb)を継承して定義します。

**エラークラスの定義:**

```ruby
# app/packages/payments/app/errors/insufficient_funds_error.rb
module Payments
  class InsufficientFundsError < DomainError
    def initialize(required:, available:)
      super(
        "Insufficient funds: required #{required}, available #{available}",
        code: "INSUFFICIENT_FUNDS",
        status: :unprocessable_entity
      )
    end
  end
end
```

**使用例:**

```ruby
class PaymentsController < ApplicationController
  def create
    if account.balance < payment_amount
      raise Payments::InsufficientFundsError.new(
        required: payment_amount,
        available: account.balance
      )
    end

    # 支払い処理
  end
end
```

**レスポンス例:**

```json
{
  "error": {
    "code": "INSUFFICIENT_FUNDS",
    "message": "Insufficient funds: required 10000, available 5000",
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  }
}
```

### 4. パッケージ固有のエラーハンドリング

モジュラーモノリスアーキテクチャでは、各パッケージで独自のエラーハンドリングを追加できます。

```ruby
# app/packages/payments/app/controllers/concerns/payment_error_handling.rb
module Payments
  module PaymentErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from Payments::PaymentGatewayError, with: :payment_gateway_error
    end

    private

    def payment_gateway_error(exception)
      render_error(
        status: :bad_gateway,
        code: "PAYMENT_GATEWAY_ERROR",
        message: "Payment gateway is temporarily unavailable"
      )
    end
  end
end

# app/packages/payments/app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  include Payments::PaymentErrorHandling

  # ...
end
```

## トレースID

全てのエラーレスポンスには`trace_id`が含まれます。これにより、エラーをログと紐付けて追跡できます。

### トレースIDの仕様

- リクエストヘッダー`X-Trace-Id`で指定可能（マイクロサービス間連携に有用）
- 未指定の場合は`request.request_id`（Rails標準のUUID）を使用
- レスポンスヘッダー`X-Trace-Id`でクライアントに返却

**リクエスト例:**

```bash
curl -H "X-Trace-Id: custom-trace-123" http://localhost:3000/users/999
```

**ログ出力例:**

```json
{
  "timestamp": "2025-10-09T12:34:56.789Z",
  "level": "error",
  "named_tags": {
    "trace_id": "custom-trace-123"
  },
  "message": "Internal Server Error: ActiveRecord::RecordNotFound - Couldn't find User with 'id'=999"
}
```

## ベストプラクティス

### 1. エラーコードの命名規則

- 大文字のスネークケースを使用（例: `INSUFFICIENT_FUNDS`）
- ビジネスドメインを反映した明確な名前をつける
- HTTPステータスコードと一致させる必要はない

### 2. エラーメッセージ

- ユーザーにとって理解しやすいメッセージを書く
- 技術的な詳細は含めない（ログには記録する）
- 多言語対応が必要な場合はi18nを使用する

### 3. カスタムエラーの配置

- 共通エラー: `app/errors/`
- パッケージ固有エラー: `app/packages/{package}/app/errors/`

### 4. 本番環境でのエラー通知

`StandardError`のハンドラーで、Sentry、Bugsnag、Rollbar等のエラー通知サービスと統合することを推奨します。

```ruby
def internal_server_error(exception)
  # エラー通知サービスに送信
  Sentry.capture_exception(exception) if defined?(Sentry)

  Rails.logger.error("Internal Server Error: #{exception.class} - #{exception.message}")
  Rails.logger.error(exception.backtrace.join("\n"))

  render_error(
    status: :internal_server_error,
    code: "INTERNAL_SERVER_ERROR",
    message: "An unexpected error occurred"
  )
end
```

## 関連ファイル

- [ErrorHandling Concern](../app/controllers/concerns/error_handling.rb)
- [ApplicationController](../app/controllers/application_controller.rb)
- [DomainError](../app/errors/domain_error.rb)
- [リクエストトレースIDミドルウェア](../app/middleware/request_trace_id.rb)
