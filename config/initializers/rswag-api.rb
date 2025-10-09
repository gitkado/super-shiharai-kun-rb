# frozen_string_literal: true

Rswag::Api.configure do |c|
  c.swagger_root = Rails.root.join("swagger").to_s

  # c.swagger_filter = lambda { |swagger, env| swagger["host"] = env["HTTP_HOST"] }
end
