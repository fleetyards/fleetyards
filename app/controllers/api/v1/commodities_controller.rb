# frozen_string_literal: true

module Api
  module V1
    class CommoditiesController < ::Api::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:commodities) }, only: [:index]

      def index
        authorize! :index, :api_commodities

        commodity_query_params['sorts'] = sort_by_name

        @q = Commodity.ransack(commodity_query_params)

        @commodities = @q.result
                         .page(params[:page])
                         .per(per_page(Commodity))
      end

      def commodity_types
        authorize! :index, :api_commodities
        @commodity_types = Commodity.type_filters
      end

      private def commodity_query_params
        @commodity_query_params ||= query_params(:name_cont, name_in: [])
      end
    end
  end
end
