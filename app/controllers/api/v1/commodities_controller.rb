# frozen_string_literal: true

module Api
  module V1
    class CommoditiesController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def index
        authorize! :index, :api_commodities

        commodity_query_params['sorts'] = sort_by_name

        @q = Commodity.ransack(commodity_query_params)

        @commodities = @q.result.offset(params[:offset]).limit(params[:limit])
      end

      private def commodity_query_params
        @commodity_query_params ||= query_params
      end
    end
  end
end
