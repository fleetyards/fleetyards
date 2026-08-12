# frozen_string_literal: true

require "yaml"

module FeatureFlags
  # Loads and validates config/feature_flags.yml, the single source of truth for
  # Flipper feature flags.
  #
  # YAML shape (mapping keyed by flag name):
  #
  #   hangar_inventories:
  #     description: "Personal hangar inventories"
  #
  #   oauth-discord:
  #     description: "Discord login"
  #     permanent: true
  #
  # Kept to plain Ruby (no Rails, no ActiveSupport) because bin/lint-feature-flags
  # loads this file without booting the application.
  class Registry
    # Hyphens are allowed because the OAuth provider gates are evaluated as
    # "oauth-#{provider}" in the frontend and cannot be renamed independently.
    NAME_PATTERN = /\A[a-z][a-z0-9_-]*\z/
    MAX_NAME_LENGTH = 60
    REQUIRED_KEYS = %w[description].freeze
    KNOWN_KEYS = %w[description permanent].freeze

    class InvalidRegistryError < StandardError; end

    def self.default_path
      if defined?(Rails)
        Rails.root.join("config/feature_flags.yml")
      else
        File.expand_path("../../config/feature_flags.yml", __dir__)
      end
    end

    # Load and validate in one step. Raises InvalidRegistryError on any problem.
    def self.load(path = default_path)
      new(path).tap(&:validate!)
    end

    # +raw+ lets tests inject a parsed hash without touching the filesystem.
    def initialize(path = self.class.default_path, raw: nil)
      @path = path
      @raw = raw || load_yaml(path)
    end

    def definitions
      @definitions ||= @raw.map { |name, attrs| build_definition(name, attrs) }
    end

    def names
      definitions.map(&:name)
    end

    def fetch(name)
      definitions.find { |definition| definition.name == name.to_s }
    end

    def validate!
      errors = validation_errors

      raise InvalidRegistryError, "Invalid feature_flags.yml:\n- #{errors.join("\n- ")}" if errors.any?

      self
    end

    # Human-readable problems; empty when the registry is valid.
    def validation_errors
      return ["root must be a mapping of flag name => attributes"] unless @raw.is_a?(Hash)

      duplicate_errors + @raw.flat_map { |name, attrs| errors_for(name, attrs) }
    end

    private def duplicate_errors
      duplicates = @raw.keys.map { |name| name.to_s.downcase }.tally.select { |_, count| count > 1 }.keys

      duplicates.map { |name| "#{name}: declared more than once" }
    end

    private def errors_for(name, attrs)
      errors = []
      errors << "#{name.inspect}: name must match #{NAME_PATTERN.source}" unless name.to_s.match?(NAME_PATTERN)
      errors << "#{name}: name exceeds #{MAX_NAME_LENGTH} characters" if name.to_s.length > MAX_NAME_LENGTH

      unless attrs.is_a?(Hash)
        errors << "#{name}: attributes must be a mapping"
        return errors
      end

      REQUIRED_KEYS.each do |key|
        errors << "#{name}: missing required key '#{key}'" if attrs[key].to_s.strip.empty?
      end

      unknown = attrs.keys.map(&:to_s) - KNOWN_KEYS
      errors << "#{name}: unknown keys #{unknown.inspect}" if unknown.any?

      unless attrs["permanent"].nil? || [true, false].include?(attrs["permanent"])
        errors << "#{name}: permanent must be a boolean"
      end

      errors
    end

    private def build_definition(name, attrs)
      attrs ||= {}

      Definition.new(
        name: name,
        description: attrs["description"],
        permanent: attrs["permanent"] == true
      )
    end

    private def load_yaml(path)
      return {} unless File.exist?(path)

      YAML.safe_load_file(path) || {}
    end
  end
end
