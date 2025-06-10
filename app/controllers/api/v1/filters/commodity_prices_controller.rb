# frozen_string_literal: true

module Api
  module V1
    module Filters
      class CommodityPricesController < ::Api::PublicBaseController
        skip_verify_authorized

        def time_ranges
          @filters = CommodityRentalPrice.time_range_filters

          render "api/v1/shared/filters"
        end
      end
    end
  end
end
