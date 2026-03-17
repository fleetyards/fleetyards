# frozen_string_literal: true

module Api
  module V1
    class UserFeaturesController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!

      def index
        @features = FeatureSetting.self_service_feature_names.filter_map do |feature_name|
          feature = Flipper.feature(feature_name)

          next if feature.state == :on

          {
            name: feature.name,
            enabled: Flipper.enabled?(feature.name, current_resource_owner)
          }
        end
      end

      def enable
        feature_name = params[:id]

        unless FeatureSetting.self_service_feature_names.include?(feature_name)
          return render json: {code: "forbidden", message: "This feature cannot be self-activated"}, status: :forbidden
        end

        Flipper.feature(feature_name).enable_actor(current_resource_owner)

        render json: {name: feature_name, enabled: true}
      end

      def disable
        feature_name = params[:id]

        unless FeatureSetting.self_service_feature_names.include?(feature_name)
          return render json: {code: "forbidden", message: "This feature cannot be self-deactivated"}, status: :forbidden
        end

        Flipper.feature(feature_name).disable_actor(current_resource_owner)

        render json: {name: feature_name, enabled: Flipper.enabled?(feature_name, current_resource_owner)}
      end
    end
  end
end
