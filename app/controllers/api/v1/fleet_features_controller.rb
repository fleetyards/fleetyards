# frozen_string_literal: true

module Api
  module V1
    class FleetFeaturesController < ::Api::BaseController
      include FeatureGrantsConcern

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.fleet", slug: params[:fleet_slug]))
      end

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[enable disable]

      before_action :set_fleet

      # Every flag the fleet's admins may switch, plus every other flag something
      # has already switched on for this fleet — its own actor gate or a group it
      # belongs to. A feature the fleet has but cannot find here reads as
      # unexplained magic.
      #
      # `toggleable` says whether the switch changes anything: it does not for a
      # flag the registry never declared fleet self-service, and it cannot take
      # away what a group grants as well, because the gates are ORed. `groups`
      # names who is responsible, since nothing here can reach a group gate.
      def index
        @features = Flipper.features.sort_by(&:key).filter_map { |feature| feature_entry(feature) }
      end

      def enable
        return unless toggleable_feature?

        Flipper.feature(params[:id]).enable_actor(@fleet)

        render json: {name: params[:id], enabled: true}
      end

      def disable
        return unless toggleable_feature?

        feature_name = params[:id]

        Flipper.feature(feature_name).disable_actor(@fleet)

        render json: {name: feature_name, enabled: Flipper.enabled?(feature_name, @fleet)}
      end

      private def feature_entry(feature)
        return if feature.state == :on

        self_service = fleet_self_service_feature_names.include?(feature.key)
        groups = feature_granting_groups(feature, @fleet)

        # A flag the fleet cannot switch only belongs here once something granted
        # it; listing the rest would name every flag in the registry on a page
        # where none of them can be switched.
        return if !self_service && groups.empty? && !feature_actor_gate?(feature, @fleet)

        {
          name: feature.name,
          enabled: Flipper.enabled?(feature.name, @fleet),
          toggleable: self_service && groups.empty?,
          groups:
        }
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :manage_features?, with: FleetPolicy
      end

      # Only flags given a fleet switch at /admin/features. A purely personal
      # flag toggled here would put a personal surface behind a fleet's admins.
      private def fleet_self_service_feature_names
        @fleet_self_service_feature_names ||= FeatureSetting.fleet_toggleable_feature_names
      end

      private def toggleable_feature?
        unless fleet_self_service_feature_names.include?(params[:id])
          render json: {code: "forbidden", message: "This feature cannot be toggled for a fleet"}, status: :forbidden

          return false
        end

        # A group grant survives clearing the fleet's own gate, so the switch
        # would report a change nobody sees.
        return true if feature_granting_groups(Flipper.feature(params[:id]), @fleet).empty?

        render json: {code: "forbidden", message: "This feature is enabled for a group this fleet is in"}, status: :forbidden

        false
      end
    end
  end
end
