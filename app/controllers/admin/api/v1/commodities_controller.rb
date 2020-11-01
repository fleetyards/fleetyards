# frozen_string_literal: true

module Admin
  module Api
    module V1
      class CommoditiesController < ::Admin::Api::BaseController
        after_action -> { pagination_header(:commodities) }, only: [:index]

        def index
          authorize! :index, :admin_api_shop_commodities

          commodities_query_params['sorts'] = 'created_at desc'

          @q = Commodity.ransack(commodities_query_params)

          @commodities = @q.result
            .page(params.fetch(:page, nil))
            .per(40)
        end

        private def commodities_query_params
          @commodities_query_params ||= query_params(
            :commodity_item_id
          )
        end
      end
    end
  end
end
