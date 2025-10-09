# ログとトレーシング

このプロジェクトでは、[SemanticLogger](https://github.com/rocketjob/semantic_logger)によるJSON形式の構造化ログを採用しています。

## 概要

SemanticLoggerは、従来のRailsのログ形式をJSON形式に変換し、ログ集約ツール（Datadog、CloudWatch等）での解析を容易にします。

## 主な特徴

- **JSON形式**: 全環境でJSON形式で出力（構造化ログ）
- **トレースID**: 全リクエストに`trace_id`が自動付与され、リクエストを横断した追跡が可能
- **モジュラーモノリス対応**: モジュールごとに独立したロガーを持てる
- **高パフォーマンス**: 非同期ロギングによる高速化

## トレースIDの仕様

### 自動生成

全てのリクエストに対して、一意のトレースIDが自動的に付与されます。

### カスタムトレースID

リクエストヘッダー`X-Trace-Id`で外部からトレースIDを指定できます。これは、マイクロサービス間の連携で特に有用です。

```bash
# トレースIDを指定したリクエスト例
curl -H "X-Trace-Id: custom-trace-123" http://localhost:3000/up
```

### レスポンスヘッダー

トレースIDはレスポンスヘッダー`X-Trace-Id`で返却されるため、クライアント側でもトレースIDを取得できます。

```bash
curl -I http://localhost:3000/up
# X-Trace-Id: 682d608d-d8e7-45cc-abd8-a2b75d30c0bf
```

## ログの出力例

### リクエストログ

```json
{
  "timestamp": "2025-10-07T13:09:06.459379Z",
  "level": "info",
  "application": "super-shiharai-kun",
  "environment": "development",
  "named_tags": {
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  },
  "name": "Rack",
  "message": "Started",
  "payload": {
    "method": "GET",
    "path": "/up"
  }
}
```

### エラーログ

```json
{
  "timestamp": "2025-10-07T13:10:15.123456Z",
  "level": "error",
  "application": "super-shiharai-kun",
  "environment": "development",
  "named_tags": {
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  },
  "name": "Rails",
  "message": "ActiveRecord::RecordNotFound: Couldn't find User with 'id'=999",
  "payload": {
    "exception": "ActiveRecord::RecordNotFound",
    "backtrace": [
      "app/controllers/users_controller.rb:10:in `show'",
      "..."
    ]
  }
}
```

## ログレベル

SemanticLoggerは以下のログレベルをサポートしています:

| レベル | 用途 |
|-------|------|
| `trace` | 詳細なデバッグ情報（開発時のみ） |
| `debug` | デバッグ情報 |
| `info` | 通常の情報 |
| `warn` | 警告 |
| `error` | エラー |
| `fatal` | 致命的なエラー |

### 環境ごとのログレベル設定

```ruby
# config/environments/development.rb
config.log_level = :debug

# config/environments/production.rb
config.log_level = :info
```

## カスタムログの出力

### 基本的な使い方

```ruby
class PaymentsController < ApplicationController
  def create
    Rails.logger.info("Payment processing started", user_id: current_user.id, amount: params[:amount])

    # 処理...

    Rails.logger.info("Payment processing completed", payment_id: payment.id)
  end
end
```

**出力例:**

```json
{
  "timestamp": "2025-10-07T13:11:20.789012Z",
  "level": "info",
  "named_tags": {
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  },
  "message": "Payment processing started",
  "payload": {
    "user_id": 123,
    "amount": 10000
  }
}
```

### パッケージ固有のロガー

モジュラーモノリスでは、各パッケージで独立したロガーを持つことができます。

```ruby
# app/packages/payments/app/controllers/payments_controller.rb
module Payments
  class PaymentsController < ApplicationController
    def create
      logger.info("Payment created", payment_id: payment.id)
    end

    private

    def logger
      @logger ||= SemanticLogger["Payments"]
    end
  end
end
```

**出力例:**

```json
{
  "timestamp": "2025-10-07T13:12:30.456789Z",
  "level": "info",
  "name": "Payments",
  "named_tags": {
    "trace_id": "682d608d-d8e7-45cc-abd8-a2b75d30c0bf"
  },
  "message": "Payment created",
  "payload": {
    "payment_id": 456
  }
}
```

### 構造化ログのベストプラクティス

1. **意味のあるメッセージ**: ログメッセージは明確で検索可能にする
2. **payloadの活用**: 追加情報は`payload`として渡す
3. **個人情報の除外**: パスワード、クレジットカード番号等は絶対にログに出力しない
4. **適切なログレベル**: 必要に応じて適切なレベルを使用する

```ruby
# 良い例
Rails.logger.info("User login successful", user_id: user.id, login_method: "email")

# 悪い例（個人情報を含む）
Rails.logger.info("User login successful", email: user.email, password: params[:password])
```

## トレースIDの活用

### エラー追跡

エラーが発生した際、トレースIDを使用してログを検索することで、リクエスト全体の流れを追跡できます。

```bash
# Datadogでの検索例
trace_id:682d608d-d8e7-45cc-abd8-a2b75d30c0bf

# CloudWatch Logsでの検索例
{ $.named_tags.trace_id = "682d608d-d8e7-45cc-abd8-a2b75d30c0bf" }
```

### マイクロサービス連携

マイクロサービス間でトレースIDを引き継ぐことで、複数のサービスにまたがるリクエストを追跡できます。

```ruby
# サービスAからサービスBへリクエスト
response = HTTP.headers(
  "X-Trace-Id" => request.headers["X-Trace-Id"]
).post("https://service-b.example.com/api/payments")
```

## 実装の詳細

### トレースIDミドルウェア

トレースIDの付与は[RequestTraceId](../app/middleware/request_trace_id.rb)ミドルウェアで実装されています。

```ruby
# app/middleware/request_trace_id.rb
class RequestTraceId
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    trace_id = request.headers["X-Trace-Id"] || SecureRandom.uuid

    # SemanticLoggerのnamed_tagsにtrace_idを追加
    SemanticLogger.tagged(trace_id: trace_id) do
      status, headers, body = @app.call(env)
      headers["X-Trace-Id"] = trace_id
      [status, headers, body]
    end
  end
end
```

### SemanticLoggerの設定

```ruby
# config/application.rb
config.rails_semantic_logger.semantic = true
config.rails_semantic_logger.started = true
config.rails_semantic_logger.processing = true
config.rails_semantic_logger.rendered = true

# トレースIDミドルウェアの追加
config.middleware.insert_before Rails::Rack::Logger, RequestTraceId
```

## トラブルシューティング

### ログが出力されない

1. ログレベルを確認: `config.log_level`が適切に設定されているか
2. ロガーの初期化: `Rails.logger`が正しく初期化されているか

### トレースIDが付与されない

1. ミドルウェアの順序: `RequestTraceId`が`Rails::Rack::Logger`より前に配置されているか
2. ヘッダー名: `X-Trace-Id`（ハイフン付き）が正しく指定されているか

### パフォーマンスへの影響

SemanticLoggerは非同期ロギングをサポートしています。大量のログを出力する場合は、非同期モードを検討してください。

```ruby
# config/environments/production.rb
SemanticLogger.sync = false  # 非同期ロギング
```

## 関連ドキュメント

- [エラーハンドリング](error_handling.md) - トレースIDとエラーレスポンスの連携
- [モジュラーモノリスアーキテクチャ](modular_monolith.md) - パッケージごとのロガー

## 関連ファイル

- [RequestTraceIdミドルウェア](../app/middleware/request_trace_id.rb)
- [Application設定](../config/application.rb)

## 参考リンク

- [SemanticLogger公式ドキュメント](https://logger.rocketjob.io/)
