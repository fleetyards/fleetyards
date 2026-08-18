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

    def initialize(name:, description:, permanent: false, self_service: false)
      @name = name.to_s
      @description = description
      @permanent = permanent == true
      @self_service_scope = normalize_scope(self_service)
    end

    # Long-lived infrastructure gates (OAuth providers, for example) rather than
    # temporary rollouts that are expected to be cleaned up again.
    def permanent?
      @permanent
    end

    # The flag ships with a self-service toggle: it arrives with a FeatureSetting
    # so it can be switched on outside /admin/features. This is the starting
    # point only — admins own it from there, see Synchronizer.
    def self_service?
      !@self_service_scope.nil?
    end

    # Who owns the toggle: the user for a personal surface, the fleet for a
    # fleet-wide one. A fleet-scoped flag never reaches personal settings, so a
    # member cannot switch on a feature for a whole fleet.
    def self_service_user?
      @self_service_scope == USER_SCOPE
    end

    def self_service_fleet?
      @self_service_scope == FLEET_SCOPE
    end

    # `true` predates the scopes and meant "users toggle this themselves", so it
    # keeps that meaning rather than forcing every personal flag to be rewritten.
    private def normalize_scope(self_service)
      case self_service
      when true then USER_SCOPE
      when String then SELF_SERVICE_SCOPES.include?(self_service) ? self_service : nil
      end
    end
  end
end
