require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Middleware classesを事前にロード
# NOTE: Railsのinsert_beforeは文字列での遅延ロードに対応していないため、
# Zeitwerkの自動リロードを一部犠牲にして明示的にrequireする必要がある
require_relative "../app/middleware/request_trace_id"

module SuperShiharaiKunRb
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # SemanticLoggerの設定
    config.rails_semantic_logger.semantic = true
    config.rails_semantic_logger.started = true
    config.rails_semantic_logger.processing = true
    config.rails_semantic_logger.rendered = true

    # トレースIDミドルウェアの追加
    config.middleware.insert_before Rails::Rack::Logger, RequestTraceId
  end
end
