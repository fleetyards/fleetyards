# frozen_string_literal: true

module Api
  module V1
    class UserFeaturesController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "profile:write" },
        unless: :user_signed_in?

      # Every self-service flag, whatever surface owns its fleet-wide switch.
      #
      # Two states, because a fleet flag has two switches with different reach:
      #
      #   enabled_for_self — this user's own gate, the one the switch here flips.
      #                      Turning a fleet flag on gives *you* the feature in
      #                      the fleets you belong to, without it appearing for
      #                      the rest of the fleet.
      #   enabled          — what the user actually has, so a feature their fleet
      #                      switched on for everyone reads as enabled rather
      #                      than as something they still have to turn on.
      #
      # `fleets` names the ones responsible, so a member can see where the feature
      # came from instead of only that they cannot switch it off.
      def index
        @features = FeatureSetting.self_service_scopes.filter_map do |feature_name, scope|
          feature = Flipper.feature(feature_name)

          next if feature.state == :on

          enabled_for_self = Flipper.enabled?(feature.name, current_resource_owner)
          fleets = granting_fleets(feature.name, scope)

          {
            name: feature.name,
            enabled: enabled_for_self || fleets.any?,
            enabled_for_self:,
            scope:,
            fleets: fleets.map { |fleet| {name: fleet.name, slug: fleet.slug} }
          }
        end
      end

      def enable
        feature_name = params[:id]

        unless FeatureSetting.self_service_anywhere?(feature_name)
          return render json: {code: "forbidden", message: "This feature cannot be self-activated"}, status: :forbidden
        end
        return if refuse_fleet_override(feature_name)

        Flipper.feature(feature_name).enable_actor(current_resource_owner)

        render json: {name: feature_name, enabled: true}
      end

      def disable
        feature_name = params[:id]

        unless FeatureSetting.self_service_anywhere?(feature_name)
          return render json: {code: "forbidden", message: "This feature cannot be self-deactivated"}, status: :forbidden
        end
        return if refuse_fleet_override(feature_name)

        Flipper.feature(feature_name).disable_actor(current_resource_owner)

        render json: {name: feature_name, enabled: Flipper.enabled?(feature_name, current_resource_owner)}
      end

      # A fleet switched the feature on for every member, and a personal gate
      # cannot take it away again — the backend ORs both actors. Refusing beats
      # reporting a change the user will not see.
      private def refuse_fleet_override(feature_name)
        return false if granting_fleets(feature_name).empty?

        render json: {code: "forbidden", message: "This feature is enabled for your fleet"}, status: :forbidden

        true
      end

      # The user's fleets that switched this feature on for their members.
      #
      # Only for a fleet-scoped flag: nothing reads a user-scoped one against a
      # fleet actor, so a gate there would grant the user nothing and must not
      # count. Accepted memberships only — a pending invitation does not give the
      # user the feature yet.
      private def granting_fleets(feature_name, scope = self_service_scope(feature_name))
        return [] unless scope == FeatureSetting::FLEET_SCOPE

        accepted_fleets.select { |fleet| Flipper.enabled?(feature_name, fleet) }
      end

      private def self_service_scope(feature_name)
        FeatureSetting.find_by(feature_name:)&.self_service_scope
      end

      private def accepted_fleets
        @accepted_fleets ||= Fleet.kept.where(
          id: current_resource_owner.fleet_memberships.kept.accepted.select(:fleet_id)
        ).to_a
      end
    end
  end
end
