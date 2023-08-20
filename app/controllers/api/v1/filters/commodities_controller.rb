# frozen_string_literal: true

module Api
  module V1
    module Filters
      class CommoditiesController < ::Api::PublicBaseController
        def commodity_types
          @commodity_types = Commodity.type_filters
        end
      end
    end
  end
end
