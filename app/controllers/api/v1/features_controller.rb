# frozen_string_literal: true

module Api
  module V1
    class FeaturesController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: %i[]

      def show
        @features = Flipper.features.filter_map do |feature|
          Flipper.enabled?(feature.name, current_resource_owner) ? feature.to_s : nil
        end
      end
    end
  end
end
