# frozen_string_literal: true

# Adds Rails.app shorthand and creds/envs/dotenvs accessors to the application.
#
# REMOVAL: Delete when upgrading to Rails 8.2.

module RailsCredsBackport
  module ApplicationExt
    def creds
      @creds ||= if Rails.env.development?
        RailsCredsBackport::CombinedConfiguration.new(envs, dotenvs, credentials)
      else
        RailsCredsBackport::CombinedConfiguration.new(envs, credentials)
      end
    end

    def creds=(value)
      @creds = value
    end

    def envs
      @envs ||= RailsCredsBackport::EnvConfiguration.new
    end

    def dotenvs(path = Rails.root.join(".env"))
      @dotenvs ||= RailsCredsBackport::DotEnvConfiguration.new(path)
    end
  end
end

Rails::Application.include(RailsCredsBackport::ApplicationExt)

# Rails.app shorthand for Rails.application
module RailsCredsBackport
  module RailsAppShorthand
    def app
      application
    end
  end
end

Rails.extend(RailsCredsBackport::RailsAppShorthand) unless Rails.respond_to?(:app)
