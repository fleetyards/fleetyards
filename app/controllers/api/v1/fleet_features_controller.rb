# frozen_string_literal: true

module Api
  module V1
    class FleetFeaturesController < ::Api::BaseController
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

      def index
        @features = fleet_self_service_feature_names.filter_map do |feature_name|
          feature = Flipper.feature(feature_name)

          next if feature.state == :on

          {
            name: feature.name,
            enabled: Flipper.enabled?(feature.name, @fleet)
          }
        end
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

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :manage_features?, with: FleetPolicy
      end

      # Only flags the registry declared fleet-scoped. A user-scoped flag toggled
      # here would put a personal surface behind a fleet's admins.
      private def fleet_self_service_feature_names
        FeatureSetting.self_service_feature_names(scope: FeatureFlags::Definition::FLEET_SCOPE)
      end

      private def toggleable_feature?
        return true if fleet_self_service_feature_names.include?(params[:id])

        render json: {code: "forbidden", message: "This feature cannot be toggled for a fleet"}, status: :forbidden

        false
      end
    end
  end
end
