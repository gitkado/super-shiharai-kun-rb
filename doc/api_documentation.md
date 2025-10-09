# API仕様書（RSwag）

このプロジェクトでは、API仕様書の自動生成のために [RSwag](https://github.com/rswag/rswag) を使用しています。RSpecのリクエストスペックからSwagger/OpenAPI形式のドキュメントを生成することで、テストとドキュメントの同期を保ちます。

## 概要

RSwagは以下を提供します:

- **Swagger UI**: ブラウザで対話的にAPIを探索
- **OpenAPI仕様**: 業界標準のAPI仕様書形式
- **テストとの同期**: RSpecテストから自動生成されるため、常に最新

## Swagger UIへのアクセス

開発サーバーを起動後、以下のURLにアクセス:

- Swagger UI: http://localhost:3000/api-docs
- 定義ファイル: `swagger/v1/swagger.yaml`

## 新しいAPIのドキュメント追加手順

### 1. RSpecリクエストスペックを作成

`spec/requests/` 配下にrswag DSLを使ったテストを作成します。

```ruby
require 'swagger_helper'  # Swagger生成に必須

RSpec.describe 'Hello API', type: :request do
  path '/hello_world' do  # → paths."/hello_world" (エンドポイント)
    get 'Returns hello world message' do  # → get.summary (HTTPメソッドと説明)
      tags 'Hello'  # → tags (Swagger UIでのグルーピング)
      produces 'application/json'  # → responses.content (レスポンス形式)

      response '200', 'successful' do  # → responses.'200'.description (ステータスコード)
        schema type: :object,  # → schema (レスポンスのデータ構造)
          properties: {
            message: { type: :string, example: 'hello world' }
          },
          required: ['message']

        run_test!  # 実際にAPIを呼び出してテスト実行（YAMLには影響しない）
      end
    end
  end
end
```

### 2. DSLとYAMLの対応関係

| DSL | 生成されるYAML |
|-----|---------------|
| `path '/hello_world'` | `paths:"/hello_world"` |
| `get '説明'` | `get: summary: 説明` |
| `tags 'Hello'` | `tags: [Hello]` |
| `produces 'application/json'` | `content: application/json` |
| `response '200', '説明'` | `responses: '200': description: 説明` |
| `schema type: :object, properties: {...}` | `schema: type: object, properties: {...}` |
| `run_test!` | YAML生成には影響せず、実際のテスト実行のみ |

### 3. Swagger YAMLを生成

```bash
RAILS_ENV=test rake rswag:specs:swaggerize
```

これにより、`swagger/v1/swagger.yaml`が生成されます。

### 4. サーバーを再起動して確認

```bash
rails s
```

http://localhost:3000/api-docs にアクセスして、Swagger UIで確認します。

## 高度な使い方

### パラメータの定義

#### パスパラメータ

```ruby
path '/users/{id}' do
  parameter name: :id, in: :path, type: :integer, description: 'User ID'

  get 'Retrieves a user' do
    tags 'Users'
    produces 'application/json'

    response '200', 'user found' do
      schema type: :object,
        properties: {
          id: { type: :integer },
          name: { type: :string }
        }

      let(:id) { User.create(name: 'John').id }
      run_test!
    end

    response '404', 'user not found' do
      let(:id) { 'invalid' }
      run_test!
    end
  end
end
```

#### クエリパラメータ

```ruby
path '/users' do
  get 'List users' do
    tags 'Users'
    produces 'application/json'
    parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
    parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'

    response '200', 'users found' do
      schema type: :array,
        items: {
          type: :object,
          properties: {
            id: { type: :integer },
            name: { type: :string }
          }
        }

      run_test!
    end
  end
end
```

#### リクエストボディ

```ruby
path '/users' do
  post 'Creates a user' do
    tags 'Users'
    consumes 'application/json'
    produces 'application/json'
    parameter name: :user, in: :body, schema: {
      type: :object,
      properties: {
        name: { type: :string },
        email: { type: :string }
      },
      required: ['name', 'email']
    }

    response '201', 'user created' do
      let(:user) { { name: 'John', email: 'john@example.com' } }
      run_test!
    end

    response '422', 'invalid request' do
      let(:user) { { name: '' } }
      run_test!
    end
  end
end
```

### 認証の定義

#### Bearer Token認証

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.swagger_docs = {
    'v1/swagger.yaml' => {
      # ...
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          }
        }
      }
    }
  }
end
```

```ruby
# spec/requests/payments_spec.rb
path '/payments' do
  post 'Creates a payment' do
    tags 'Payments'
    security [bearerAuth: []]  # 認証が必要
    consumes 'application/json'
    produces 'application/json'

    parameter name: :payment, in: :body, schema: {
      type: :object,
      properties: {
        amount: { type: :integer }
      }
    }

    response '201', 'payment created' do
      let(:Authorization) { "Bearer #{jwt_token}" }
      let(:payment) { { amount: 10000 } }
      run_test!
    end

    response '401', 'unauthorized' do
      let(:Authorization) { 'Bearer invalid_token' }
      let(:payment) { { amount: 10000 } }
      run_test!
    end
  end
end
```

### 複雑なスキーマ定義

#### ネストしたオブジェクト

```ruby
response '200', 'invoice found' do
  schema type: :object,
    properties: {
      id: { type: :integer },
      amount: { type: :integer },
      user: {
        type: :object,
        properties: {
          id: { type: :integer },
          name: { type: :string },
          email: { type: :string }
        }
      },
      line_items: {
        type: :array,
        items: {
          type: :object,
          properties: {
            id: { type: :integer },
            name: { type: :string },
            price: { type: :integer }
          }
        }
      }
    },
    required: ['id', 'amount', 'user']

  run_test!
end
```

#### スキーマの再利用

```ruby
# spec/support/schemas.rb
module Schemas
  USER_SCHEMA = {
    type: :object,
    properties: {
      id: { type: :integer },
      name: { type: :string },
      email: { type: :string }
    },
    required: ['id', 'name', 'email']
  }.freeze

  INVOICE_SCHEMA = {
    type: :object,
    properties: {
      id: { type: :integer },
      amount: { type: :integer },
      user: USER_SCHEMA
    },
    required: ['id', 'amount', 'user']
  }.freeze
end
```

```ruby
# spec/requests/invoices_spec.rb
require 'support/schemas'

response '200', 'invoice found' do
  schema Schemas::INVOICE_SCHEMA
  run_test!
end
```

## テスト実行

### 全テスト実行

```bash
bundle exec rspec
```

### 特定のスペックのみ実行

```bash
bundle exec rspec spec/requests/hello_spec.rb
```

### Swagger生成とテストの分離

- `run_test!`を含む: テスト実行 + YAML生成
- `run_test!`を省略: YAML生成のみ（テストはスキップ）

通常は`run_test!`を含めることで、テストとドキュメントの同期を保ちます。

## ベストプラクティス

### 1. テストとドキュメントは常に同期

`run_test!`を必ず含めることで、ドキュメントが実際の動作を反映することを保証します。

### 2. 全てのレスポンスを定義

成功ケースだけでなく、エラーケース（400, 401, 404, 422, 500等）も定義します。

```ruby
response '200', 'success' do
  run_test!
end

response '404', 'not found' do
  let(:id) { 'invalid' }
  run_test!
end

response '401', 'unauthorized' do
  let(:Authorization) { nil }
  run_test!
end
```

### 3. exampleを活用

`example`属性を使用して、具体的な値を示します。

```ruby
schema type: :object,
  properties: {
    amount: { type: :integer, example: 10000 },
    currency: { type: :string, example: 'JPY' }
  }
```

### 4. descriptionを追加

パラメータやレスポンスに説明を追加して、理解しやすくします。

```ruby
parameter name: :amount,
  in: :body,
  type: :integer,
  description: '支払金額（円単位、手数料を除く）',
  example: 10000
```

### 5. パッケージごとにタグを使用

モジュラーモノリスでは、パッケージごとにタグを分けると見やすくなります。

```ruby
# app/packages/payments/spec/requests/payments_spec.rb
tags 'Payments'  # Swagger UIで「Payments」グループに表示

# app/packages/authentication/spec/requests/sessions_spec.rb
tags 'Authentication'  # Swagger UIで「Authentication」グループに表示
```

## 注意事項

### 通常のRSpecテストとの共存

`swagger_helper`をrequireしたテストのみがSwagger生成対象になります。通常のRSpecテストと共存可能です。

```ruby
# Swagger生成対象
require 'swagger_helper'

# 通常のRSpecテスト（Swagger生成対象外）
require 'rails_helper'
```

### 手動編集は非推奨

`swagger/v1/swagger.yaml`を手動で編集することも可能ですが、次回の生成時に上書きされるため非推奨です。

### CI/CDでの自動生成

CI/CDパイプラインでSwagger生成を自動化することを推奨します。

```yaml
# GitHub Actionsの例
- name: Generate Swagger docs
  run: RAILS_ENV=test bundle exec rake rswag:specs:swaggerize
```

## トラブルシューティング

### Swagger UIが表示されない

1. サーバーを再起動
2. `swagger/v1/swagger.yaml`が生成されているか確認
3. ブラウザのキャッシュをクリア

### スキーマエラー

```bash
# 生成されたYAMLの妥当性をチェック
bundle exec rake rswag:specs:swaggerize
```

エラーメッセージを確認して、スキーマ定義を修正します。

## 関連ドキュメント

- [モジュラーモノリスアーキテクチャ](modular_monolith.md) - パッケージ単位でのAPI管理
- [エラーハンドリング](error_handling.md) - エラーレスポンスの定義

## 関連ファイル

- [Swagger Helper](../spec/swagger_helper.rb)
- [サンプルスペック](../app/packages/hello/spec/requests/hello_spec.rb)

## 参考リンク

- [RSwag公式ドキュメント](https://github.com/rswag/rswag)
- [OpenAPI Specification](https://swagger.io/specification/)
