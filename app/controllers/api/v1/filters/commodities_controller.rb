# frozen_string_literal: true

module Api
  module V1
    module Filters
      class CommoditiesController < ::Api::PublicBaseController
        skip_verify_authorized

        def types
          @filters = Commodity.type_filters

          render "api/v1/shared/filters"
        end
      end
    end
  end
end
