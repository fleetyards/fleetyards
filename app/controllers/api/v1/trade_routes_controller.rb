# frozen_string_literal: true

module Api
  module V1
    class TradeRoutesController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: %i[]
      after_action -> { pagination_header(:trade_routes) }, only: [:index]

      def index
        authorize! :index, :api_trade_routes

        trade_routes_query_params['sorts'] = ['profit_per_unit desc', 'origin_shop_station_name asc']

        @q = TradeRoute.with_profit.ransack(trade_routes_query_params)

        @trade_routes = @q.result
                          .page(params[:page])
                          .per(per_page(TradeRoute))
      end

      private def trade_routes_query_params
        @trade_routes_query_params ||= query_params(
          station_in: [], celestial_object_in: [], starsystem_in: [], commodity_in: [], commodity_type_in: []
        )
      end
    end
  end
end
