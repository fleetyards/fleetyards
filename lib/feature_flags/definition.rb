# frozen_string_literal: true

module FeatureFlags
  # Immutable value object for a single feature flag as declared in the registry.
  #
  # Holds no Flipper state (whether the flag is currently on, off or gated) and
  # nothing about self-service — only the declarative metadata the registry owns.
  # Whether a flag may be toggled outside /admin/features, and which surface that
  # toggle lives on, are both decided there; see FeatureSetting.
  #
  # Kept to plain Ruby (no Rails, no ActiveSupport) because
  # `bin/feature-flags validate` loads this file without booting the application.
  class Definition
    attr_reader :name, :description

    def initialize(name:, description:, permanent: false)
      @name = name.to_s
      @description = description
      @permanent = permanent == true
    end

    # Long-lived infrastructure gates (OAuth providers, for example) rather than
    # temporary rollouts that are expected to be cleaned up again.
    def permanent?
      @permanent
    end
  end
end
