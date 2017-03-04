# encoding: utf-8
# frozen_string_literal: true
require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Fleetyards
  class Application < Rails::Application
    config.lograge.enabled = true
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Berlin'

    # The default locale is :de and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.default_locale = :en
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]

    config.i18n.fallbacks = [:en]

    config.action_view.field_error_proc = proc { |html_tag, _instance|
      # rubocop:disable Rails/OutputSafety
      html_tag.to_s.html_safe
    }
    config.autoload_paths << Rails.root.join("config", "routes")

    config.exceptions_app = routes

    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins "localhost", "fleetyards.dev", "fleetyards.net", "d159vi9qupesbj.cloudfront.net"
        resource "*", headers: :any, methods: [:get]
      end
    end
  end
end

I18n.config.enforce_available_locales = true
require_relative 'version'
