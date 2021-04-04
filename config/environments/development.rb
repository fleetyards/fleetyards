# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.hosts << ".#{Rails.application.secrets[:domain]}"
  config.hosts << Rails.application.secrets[:invite_domain]

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'], db: ENV['REDIS_DB'] || 0 }

    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.deliver_later_queue_name = 'mailers'
  config.action_mailer.default_url_options = { host: Rails.application.secrets[:domain], trailing_slash: true }
  config.action_mailer.asset_host = Rails.application.secrets[:frontend_endpoint]
  config.action_mailer.smtp_settings = {
    address: '127.0.0.1',
    port: 1025,
    enable_starttls_auto: true,
    domain: Rails.application.secrets[:domain]
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  config.action_cable.url = Rails.application.secrets[:cable_endpoint]
  config.action_cable.allowed_request_origins = ['http://www.fleetyards.test', 'http://fleetyards.test', 'http://localhost:8270', 'http://0.0.0.0:8270']

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.logger = ActiveSupport::Logger.new(config.paths['log'].first, 1, 10.megabytes)

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
