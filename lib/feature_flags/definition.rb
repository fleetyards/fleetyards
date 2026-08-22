# frozen_string_literal: true

module FeatureFlags
  # Immutable value object for a single feature flag as declared in the registry.
  #
  # Holds no Flipper state (whether the flag is currently on, off or gated) —
  # only the declarative metadata the registry owns.
  #
  # Kept to plain Ruby (no Rails, no ActiveSupport) because
  # `bin/feature-flags validate` loads this file without booting the application.
  class Definition
    USER_SCOPE = "user"
    FLEET_SCOPE = "fleet"
    SELF_SERVICE_SCOPES = [USER_SCOPE, FLEET_SCOPE].freeze

    attr_reader :name, :description, :self_service_scope

    # +self_service_scope+ is which surface a toggle for this flag belongs on:
    # the user for a personal one, the fleet for a fleet-wide one. A fleet-scoped
    # flag never reaches personal settings, so a member cannot switch a feature
    # on for a whole fleet. nil leaves the surface unclaimed, and the column
    # default takes over.
    #
    # None of it says whether a toggle is offered at all — that is
    # `feature_settings.self_service`, which only /admin/features writes.
    def initialize(name:, description:, permanent: false, self_service_scope: nil)
      @name = name.to_s
      @description = description
      @permanent = permanent == true
      @self_service_scope = normalize_scope(self_service_scope)
    end

    # Long-lived infrastructure gates (OAuth providers, for example) rather than
    # temporary rollouts that are expected to be cleaned up again.
    def permanent?
      @permanent
    end

    private def normalize_scope(scope)
      scope if SELF_SERVICE_SCOPES.include?(scope)
    end
  end
end
