# frozen_string_literal: true

require_relative "../../../../../spec/swagger_helper"

RSpec.describe "Hello API", type: :request do
  path "/hello_world" do
    get "Returns hello world message" do
      tags "Hello"
      produces "application/json"

      response "200", "successful" do
        schema type: :object,
          properties: {
            message: { type: :string, example: "hello world" }
          },
          required: [ "message" ]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to eq("hello world")
        end
      end
    end
  end
end
