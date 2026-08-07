# frozen_string_literal: true

module Api
  module V1
    class FleetResourceAccessCatalogController < ::Api::PublicBaseController
      skip_verify_authorized

      def index
        @groups = FleetRole.privilege_groups
      end
    end
  end
end
