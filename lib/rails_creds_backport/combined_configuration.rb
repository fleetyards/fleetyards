# frozen_string_literal: true

module RailsCredsBackport
  # Queries multiple configuration backends in order, returning the first non-nil value.
  # Used by Rails.app.creds to unify ENV, .env, and encrypted credentials.
  #
  # REMOVAL: Delete when upgrading to Rails 8.2 (ActiveSupport::CombinedConfiguration).
  class CombinedConfiguration
    def initialize(*configurations)
      @configurations = configurations
    end

    # Find a key across all backends. Raises KeyError if none hold it.
    def require(*key)
      @configurations.each do |config|
        value = config.option(*key)
        return value unless value.nil?
      end

      raise KeyError, "Missing key: #{key.inspect}"
    end

    # Find a key across all backends. Returns nil (or default) if none hold it.
    def option(*key, default: nil)
      @configurations.each do |config|
        value = config.option(*key)
        return value unless value.nil?
      end

      default.respond_to?(:call) ? default.call : default
    end

    def reload
      @configurations.each { |config| config.try(:reload) }
    end
  end
end
