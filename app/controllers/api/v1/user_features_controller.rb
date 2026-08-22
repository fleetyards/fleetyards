# frozen_string_literal: true

module Api
  module V1
    class UserFeaturesController < ::Api::BaseController
      include FeatureGrantsConcern

      skip_verify_authorized

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "profile:write" },
        unless: :user_signed_in?

      # Every flag the user has a personal switch for, plus every other flag
      # something has already switched on for them — their own actor gate, a
      # group they are in, or one of their fleets. A feature the user has but
      # cannot find here reads as unexplained magic.
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
      #                      not without a personal switch, and it cannot take
      #                      away what a fleet or a group grants too, because the
      #                      gates are ORed.
      #
      # `fleets` and `groups` name who is responsible, so a member can see where
      # the feature came from instead of only that they cannot switch it off.
      def index
        @features = Flipper.features.sort_by(&:key).filter_map { |feature| feature_entry(feature) }
      end

      def enable
        feature_name = params[:id]

        unless FeatureSetting.user_toggleable?(feature_name)
          return render json: {code: "forbidden", message: "This feature cannot be self-activated"}, status: :forbidden
        end
        return if refuse_external_grant(feature_name)

        Flipper.feature(feature_name).enable_actor(current_resource_owner)

        render json: {name: feature_name, enabled: true}
      end

      def disable
        feature_name = params[:id]

        unless FeatureSetting.user_toggleable?(feature_name)
          return render json: {code: "forbidden", message: "This feature cannot be self-deactivated"}, status: :forbidden
        end
        return if refuse_external_grant(feature_name)

        Flipper.feature(feature_name).disable_actor(current_resource_owner)

        render json: {name: feature_name, enabled: Flipper.enabled?(feature_name, current_resource_owner)}
      end

      private def feature_entry(feature)
        return if feature.state == :on

        own_switch = user_toggleable?(feature)
        fleets = granting_fleets(feature)
        groups = granting_groups(feature)
        enabled_for_self = personal_gate?(feature)

        # Without a switch of their own, the flag is only the user's business
        # once something granted it to them; listing the rest would name every
        # flag in the registry on a page where none of them can be switched.
        return if !own_switch && !enabled_for_self && fleets.empty? && groups.empty?

        {
          name: feature.name,
          enabled: Flipper.enabled?(feature.name, current_resource_owner) || fleets.any?,
          enabled_for_self:,
          # Fleet-scoped either because a fleet's admins have a switch of their
          # own for it, or — for a flag with no switch anywhere — because a fleet
          # is what granted it. Both tell the page the switch here covers only
          # the viewer.
          scope: (fleet_toggleable?(feature) || fleets.any?) ? FeatureSetting::FLEET_SCOPE : FeatureSetting::USER_SCOPE,
          toggleable: own_switch && fleets.empty? && groups.empty?,
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
      # Skipped for a flag that is only ever read against a user: a gate on a
      # fleet would grant them nothing there and must not count. A flag with a
      # fleet switch is read against the fleet, and so is one with no switch at
      # all, so both count. Accepted memberships only — a pending invitation does
      # not give the user the feature yet.
      private def granting_fleets(feature)
        return [] if user_toggleable?(feature) && !fleet_toggleable?(feature)

        accepted_fleets.select { |fleet| Flipper.enabled?(feature.name, fleet) }
      end

      private def user_toggleable?(feature)
        user_toggleable_names.include?(feature.key)
      end

      private def fleet_toggleable?(feature)
        fleet_toggleable_names.include?(feature.key)
      end

      private def user_toggleable_names
        @user_toggleable_names ||= FeatureSetting.user_toggleable_feature_names.to_set
      end

      private def fleet_toggleable_names
        @fleet_toggleable_names ||= FeatureSetting.fleet_toggleable_feature_names.to_set
      end

      private def accepted_fleets
        @accepted_fleets ||= Fleet.kept.where(
          id: current_resource_owner.fleet_memberships.kept.accepted.select(:fleet_id)
        ).to_a
      end
    end
  end
end
