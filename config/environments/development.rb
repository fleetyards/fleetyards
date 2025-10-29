require "active_support/core_ext/integer/time"
require "app_endpoint_resolver"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  endpoints = AppEndpointResolver.new

  config.hosts << ".#{Rails.configuration.app.domain}"
  config.hosts << Rails.configuration.app.short_domain

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  config.debug_exception_response_format = :api

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local
  config.active_storage.routes_prefix = "/files"

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :redis_cache_store, {url: Rails.configuration.redis.url, db: Rails.configuration.redis.db}

    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local

  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.deliver_later_queue_name = "mailers"
  config.action_mailer.default_url_options = {host: Rails.configuration.app.domain, trailing_slash: true}
  config.action_mailer.asset_host = endpoints.frontend_endpoint

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true
  config.action_controller.asset_host = endpoints.frontend_endpoint

  config.action_cable.url = endpoints.cable_endpoint
  config.action_cable.allowed_request_origins = [
    "http://localhost:#{ENV["PORT"]}",
    endpoints.frontend_endpoint,
    endpoints.admin_endpoint
  ]

  config.logger = ActiveSupport::Logger.new(config.paths["log"].first, 1, 10.megabytes)

  config.after_initialize do
    Bullet.enable = true
    Bullet.sentry = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
    Bullet.skip_html_injection = true
  end
end
