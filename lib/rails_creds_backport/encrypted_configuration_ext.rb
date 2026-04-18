# frozen_string_literal: true

# Adds require/option/reload to EncryptedConfiguration so it can serve
# as a backend for CombinedConfiguration, matching the Rails 8.2 API.
#
# REMOVAL: Delete when upgrading to Rails 8.2.

module RailsCredsBackport
  module EncryptedConfigurationExt
    def require(*key)
      value = dig(*key)
      return value unless value.nil?

      raise KeyError, "Missing key: #{key.inspect}"
    end

    def option(*key, default: nil)
      value = dig(*key)

      if !value.nil?
        value
      elsif default.respond_to?(:call)
        default.call
      else
        default
      end
    end

    def reload
      @config = @options = nil
    end
  end
end

ActiveSupport::EncryptedConfiguration.prepend(RailsCredsBackport::EncryptedConfigurationExt)
