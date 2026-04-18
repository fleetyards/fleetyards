# frozen_string_literal: true

module RailsCredsBackport
  # Wraps ENV with a require/option API matching EncryptedConfiguration.
  # Keys are accepted as symbols, uppercased, and joined with "__" for nesting.
  #
  # REMOVAL: Delete when upgrading to Rails 8.2 (ActiveSupport::EnvConfiguration).
  class EnvConfiguration
    def initialize
      reload
    end

    # Fetch a key from ENV. Raises KeyError if missing.
    #
    #   require(:db_host)         # => ENV.fetch("DB_HOST")
    #   require(:database, :host) # => ENV.fetch("DATABASE__HOST")
    def require(*key)
      @envs.fetch envify(*key)
    end

    # Fetch a key from ENV. Returns nil (or default) if missing.
    #
    #   option(:db_host)                             # => ENV["DB_HOST"]
    #   option(:db_host, default: "localhost")        # => ENV.fetch("DB_HOST", "localhost")
    #   option(:db_host, default: -> { "localhost" }) # => ENV.fetch("DB_HOST") { "localhost" }
    def option(*key, default: nil)
      if default.respond_to?(:call)
        @envs.fetch(envify(*key)) { default.call }
      elsif default
        @envs.fetch(envify(*key), default)
      else
        @envs[envify(*key)]
      end
    end

    def reload
      @envs = ENV.to_h
    end

    private

    def envify(*key)
      key.collect { |part| part.to_s.upcase }.join("__")
    end
  end
end
