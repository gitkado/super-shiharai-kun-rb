# frozen_string_literal: true

# Centralized application configuration backed by ENV variables.
module AppConfig
  module_function

  def jwt_secret
    @jwt_secret ||= ENV.fetch("JWT_SECRET_KEY")
  end

  def rails_log_level
    ENV.fetch("RAILS_LOG_LEVEL", "info")
  end

  def rails_max_threads(default_value = 5)
    fetch_integer("RAILS_MAX_THREADS", default_value)
  end

  def port(default_value = 3000)
    fetch_integer("PORT", default_value)
  end

  def pidfile
    ENV["PIDFILE"]
  end

  def redis_url(default_value = "redis://localhost:6379/1")
    ENV.fetch("REDIS_URL", default_value)
  end

  def database_password
    ENV["SUPER_SHIHARAI_KUN_RB_DATABASE_PASSWORD"]
  end

  def ci?
    env_set?("CI")
  end

  class << self
    private

    def env_set?(key)
      value = ENV[key]
      value && !value.empty?
    end

    def fetch_integer(key, default_value)
      ENV.fetch(key, default_value).to_i
    end
  end
end
