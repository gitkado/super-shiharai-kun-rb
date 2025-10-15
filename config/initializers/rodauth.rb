# frozen_string_literal: true

require "rodauth/rails"
require "sequel/core"

# Configure Sequel to use ActiveRecord connection
require "sequel/extensions/activerecord_connection"

# Lazy load Rodauth configuration to avoid table existence checks during boot
Rails.application.config.after_initialize do
  Sequel::DATABASES.first&.extension(:activerecord_connection) if defined?(Sequel::DATABASES)
end

Rodauth::Rails.configure do |config|
  config.app = "RodauthApp"
end
