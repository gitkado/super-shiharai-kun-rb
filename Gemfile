# frozen_string_literal: true

source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Authentication with Rodauth and JWT
gem "rodauth-rails", "~> 2.1"
gem "jwt", "~> 2.10"
gem "bcrypt", "~> 3.1"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

# Structured logging with JSON format support
gem "rails_semantic_logger"

# Modular monolith architecture with Packwerk
gem "packwerk", "~> 3.2"
gem "packwerk-extensions", "~> 0.3.0"
gem "packs-rails"  # Packs integration for Rails
gem "ostruct"  # Required for Ruby >= 3.5 (not bundled by default)

group :development, :test do
  # Load environment variables from .env file
  gem "dotenv-rails"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false
  gem "bundler-audit", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-packs", require: false  # Packwerk用RuboCop拡張
  # omakase in:
  # - gem "rubocop", require: false
  # - gem "rubocop-rails", require: false
  # - gem "rubocop-performance", require: false

  # Testing framework
  gem "rspec-rails", "~> 7.1"

  # API Documentation with Swagger UI
  # NOTE: Railsエンジンとして起動時に統合する必要があるため`require: false`は指定しない
  gem "rswag-api"
  gem "rswag-specs"  # RSpecからYAML生成
  gem "rswag-ui"

  gem "lefthook", require: false
  # gem "simplecov", require: false

  # N+1 query detection [https://github.com/flyerhzm/bullet]
  gem "bullet"

  # Language Server Protocol (LSP) for Ruby and Rails
  gem "ruby-lsp", require: false
  gem "ruby-lsp-rails", require: false
  gem "ruby-lsp-rspec", require: false
end
