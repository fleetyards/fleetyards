# frozen_string_literal: true

module Api
  module V1
    module Filters
      class VehiclesController < ::Api::PublicBaseController
        skip_verify_authorized

        def bought_via
          @filters = Vehicle.bought_via_filters

          render "api/v1/shared/filters"
        end
      end
    end
  end
end
