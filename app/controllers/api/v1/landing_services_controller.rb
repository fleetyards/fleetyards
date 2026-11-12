# frozen_string_literal: true

module Api
  module V1
    class LandingServicesController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index]

      def index
        @landing_services = LandingService.includes(icon_attachment: :blob).ordered
      end
    end
  end
end
