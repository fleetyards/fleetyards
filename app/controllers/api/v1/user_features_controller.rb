# frozen_string_literal: true

module Api
  module V1
    class UserFeaturesController < ::Api::BaseController
      include FeatureGrantsConcern

      skip_verify_authorized

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "profile:write" },
        unless: :user_signed_in?

      # Every self-service flag, whatever surface owns its fleet-wide switch,
      # plus every other flag something has already switched on for this user —
      # their own actor gate, a group they are in, or one of their fleets. A
      # feature the user has but cannot find here reads as unexplained magic.
      #
      # Three states, because a flag has more switches than the one on this page:
      #
      #   enabled_for_self — this user's own actor gate, the one the switch here
      #                      flips. For a fleet flag that is a preview for them
      #                      alone, without it appearing for the rest of the
      #                      fleet.
      #   enabled          — what the user actually has, so a feature granted
      #                      elsewhere reads as enabled rather than as something
      #                      they still have to turn on.
      #   toggleable       — whether the switch here changes anything. It does
      #                      not without a self-service toggle, and it cannot
      #                      take away what a fleet or a group grants too,
      #                      because the gates are ORed.
      #
      # `fleets` and `groups` name who is responsible, so a member can see where
      # the feature came from instead of only that they cannot switch it off.
      def index
        @features = Flipper.features.sort_by(&:key).filter_map { |feature| feature_entry(feature) }
      end

      def enable
        feature_name = params[:id]

        unless FeatureSetting.self_service_anywhere?(feature_name)
          return render json: {code: "forbidden", message: "This feature cannot be self-activated"}, status: :forbidden
        end
        return if refuse_external_grant(feature_name)

        Flipper.feature(feature_name).enable_actor(current_resource_owner)

        render json: {name: feature_name, enabled: true}
      end

      def disable
        feature_name = params[:id]

        unless FeatureSetting.self_service_anywhere?(feature_name)
          return render json: {code: "forbidden", message: "This feature cannot be self-deactivated"}, status: :forbidden
        end
        return if refuse_external_grant(feature_name)

        Flipper.feature(feature_name).disable_actor(current_resource_owner)

        render json: {name: feature_name, enabled: Flipper.enabled?(feature_name, current_resource_owner)}
      end

      private def feature_entry(feature)
        return if feature.state == :on

        scope = self_service_scopes[feature.key]
        fleets = granting_fleets(feature, scope)
        groups = granting_groups(feature)
        enabled_for_self = personal_gate?(feature)

        # A flag with no self-service toggle is only the user's business once
        # something granted it to them; listing the rest would name every flag in
        # the registry on a page where none of them can be switched.
        return if scope.nil? && !enabled_for_self && fleets.empty? && groups.empty?

        {
          name: feature.name,
          enabled: Flipper.enabled?(feature.name, current_resource_owner) || fleets.any?,
          enabled_for_self:,
          # A flag the registry never declared self-service has no owning
          # surface, so the grant names it: a fleet gate makes this a fleet
          # matter, anything else is the user's own.
          scope: scope || (fleets.any? ? FeatureFlags::Definition::FLEET_SCOPE : FeatureFlags::Definition::USER_SCOPE),
          toggleable: !scope.nil? && fleets.empty? && groups.empty?,
          fleets: fleets.map { |fleet| {name: fleet.name, slug: fleet.slug} },
          groups:
        }
      end

      # A fleet or a group switched the feature on, and a personal gate cannot
      # take it away again — the backend ORs every gate. Refusing beats reporting
      # a change the user will not see.
      private def refuse_external_grant(feature_name)
        feature = Flipper.feature(feature_name)
        fleets = granting_fleets(feature)
        groups = granting_groups(feature)

        return false if fleets.empty? && groups.empty?

        message = fleets.any? ? "This feature is enabled for your fleet" : "This feature is enabled for a group you are in"
        render json: {code: "forbidden", message:}, status: :forbidden

        true
      end

      private def personal_gate?(feature)
        feature_actor_gate?(feature, current_resource_owner)
      end

      private def granting_groups(feature)
        feature_granting_groups(feature, current_resource_owner)
      end

      # The user's fleets that switched this feature on for their members.
      #
      # Skipped for a user-scoped flag: nothing reads a personal surface's flag
      # against a fleet actor, so a gate there would grant the user nothing and
      # must not count. A flag with no self-service scope has no such surface, so
      # its fleet gates do count. Accepted memberships only — a pending
      # invitation does not give the user the feature yet.
      private def granting_fleets(feature, scope = self_service_scopes[feature.key])
        return [] if scope == FeatureFlags::Definition::USER_SCOPE

        accepted_fleets.select { |fleet| Flipper.enabled?(feature.name, fleet) }
      end

      private def self_service_scopes
        @self_service_scopes ||= FeatureSetting.self_service_scopes.to_h
      end

      private def accepted_fleets
        @accepted_fleets ||= Fleet.kept.where(
          id: current_resource_owner.fleet_memberships.kept.accepted.select(:fleet_id)
        ).to_a
      end
    end
  end
end
