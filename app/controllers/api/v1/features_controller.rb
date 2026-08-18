# frozen_string_literal: true

module Api
  module V1
    class FeaturesController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: %i[]

      # The viewer's own flags only. Flags enabled for a fleet ride on that
      # fleet's payload instead — folding them in here answered "on for any fleet
      # you are in", which showed a fleet's features on every other fleet's page.
      def show
        @features = Flipper.features.filter_map do |feature|
          Flipper.enabled?(feature.name, current_resource_owner) ? feature.to_s : nil
        end
      end
    end
  end
end
