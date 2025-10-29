# frozen_string_literal: true

module Api
  module V1
    class FeaturesController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: %i[]

      def show
        user_features = Flipper.features.filter_map do |feature|
          Flipper.enabled?(feature.name, current_resource_owner) ? feature.to_s : nil
        end
        fleet_features = Flipper.features.filter_map do |feature|
          Flipper.enabled?(feature.name, current_resource_owner&.fleets) ? feature.to_s : nil
        end

        @features = (user_features + fleet_features).uniq
      end
    end
  end
end
