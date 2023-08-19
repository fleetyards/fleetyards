# frozen_string_literal: true

module Api
  module V1
    module Filters
      class CommoditiesController < ::Api::PublicBaseController
        def commodity_types
          authorize! :index, :api_commodities
          @commodity_types = Commodity.type_filters
        end
      end
    end
  end
end
