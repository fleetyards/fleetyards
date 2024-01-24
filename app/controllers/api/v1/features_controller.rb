# frozen_string_literal: true

module Api
  module V1
    class FeaturesController < ::Api::BaseController
      def show
        authorize! :show, :api_features

        @features = Flipper.features.filter_map do |feature|
          Flipper.enabled?(feature.name, current_user) ? feature.to_s : nil
        end
      end
    end
  end
end
