# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'スーパー支払い君 API',
        version: 'v1',
        description: '企業向け支払い管理システムのREST API'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: '開発環境'
        },
        {
          url: 'https://{defaultHost}',
          description: '本番環境',
          variables: {
            defaultHost: {
              default: 'api.super-shiharai-kun.com'
            }
          }
        }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT',
            description: 'JWT認証トークン（ログイン/登録APIで取得）'
          }
        },
        schemas: {
          ErrorResponse: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: { type: :string, example: 'VALIDATION_ERROR' },
                  message: { type: :string, example: 'Email has already been taken' },
                  trace_id: { type: :string, example: '682d608d-d8e7-45cc-abd8-a2b75d30c0bf' }
                },
                required: [ :code, :message, :trace_id ]
              }
            },
            required: [ :error ]
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
