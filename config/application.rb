# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'
# require 'rails'
#
# # Pick the frameworks you want:
# require 'active_record/railtie' # this adds "active_model/railtie" for us
# # require "active_storage/engine"
# require 'action_controller/railtie'
# require 'action_view/railtie'
# require 'action_mailer/railtie'
# require 'active_job/railtie'
# require 'action_cable/engine'
# # require "action_mailbox/engine"
# # require "action_text/engine"
# require 'rails/test_unit/railtie'
# require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fleetyards
  class Application < Rails::Application
    config.lograge.enabled = true
    config.lograge.ignore_actions = ['Api::BaseController#version']

    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Berlin'

    # The default locale is :de and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.default_locale = :en
    config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.{rb,yml}').to_s]

    config.i18n.fallbacks = [:en]

    config.active_job.queue_adapter = :sidekiq
    config.active_job.queue_name_prefix = 'fleetyards'
    config.active_job.queue_name_delimiter = '_'

    config.action_view.field_error_proc = proc { |html_tag, _instance|
      # rubocop:disable Rails/OutputSafety
      html_tag.to_s.html_safe
      # rubocop:enable Rails/OutputSafety
    }
    config.autoload_paths << Rails.root.join('config/routes')

    # Hack to fix Zeitwerk issue
    Rails.autoloaders.main.ignore(Rails.root.join('app/packs/images'))

    config.exceptions_app = routes

    config.middleware.use Rack::Attack

    config.app = config_for('app/main')
    config.maintainer = config_for('app/maintainer')
    config.rsi = config_for('app/rsi')
    config.redis = config_for(:redis)
    config.basic_auth = config_for(:basic_auth)

    config.cookie_prefix = Rails.env.production? ? Rails.configuration.app.cookie_prefix : "#{Rails.configuration.app.cookie_prefix}_#{Rails.env.upcase}"
  end
end

I18n.config.enforce_available_locales = true
require_relative 'version'
