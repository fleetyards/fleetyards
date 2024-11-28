require_relative "boot"

require "rails/all"
require "sprockets/railtie"
require_relative "../lib/middleware/transform_parameters"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fleetyards
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Berlin"
    # config.eager_load_paths << Rails.root.join("extras")

    # The default locale is :de and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.default_locale = :en
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}").to_s]
    config.i18n.available_locales = %i[en de es fr it zh-CN zh-TW]
    config.i18n.fallbacks = [:en]

    # Use a real queuing backend for Active Job (and separate queues per environment).
    config.active_job.queue_adapter = :sidekiq

    config.lograge.enabled = true
    config.lograge.ignore_actions = ["Api::BaseController#version"]

    config.action_view.field_error_proc = proc { |html_tag, _instance|
      # rubocop:disable Rails/OutputSafety
      html_tag.to_s.html_safe
      # rubocop:enable Rails/OutputSafety
    }

    config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, ActiveSupport::HashWithIndifferentAccess]

    # Hack to fix Zeitwerk issue
    Rails.autoloaders.main.ignore(Rails.root.join("app/frontend/images"))

    config.exceptions_app = routes

    config.middleware.use Rack::Attack
    config.middleware.use Rack::Deflater
    config.middleware.use Middleware::TransformParameters

    config.app = config_for("app/main")
    config.maintainer = config_for("app/maintainer")
    config.rsi = config_for("app/rsi")
    config.api_schema = config_for("app/api_schema")
    config.redis = config_for(:redis)
    config.basic_auth = config_for(:basic_auth)

    # Disable Google's FLoC User Tracking - as recommended by Andy Croll ;) https://andycroll.com/ruby/opt-out-of-google-floc-tracking-in-rails/
    config.action_dispatch.default_headers["Permissions-Policy"] = "interest-cohort=()"

    config.cookie_prefix = Rails.env.production? ? Rails.configuration.app.cookie_prefix : "#{Rails.configuration.app.cookie_prefix}_#{Rails.env.upcase}"
  end
end

I18n.config.enforce_available_locales = true
require_relative "version"
