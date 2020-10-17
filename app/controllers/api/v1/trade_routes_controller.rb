# frozen_string_literal: true

module Api
  module V1
    class TradeRoutesController < ::Api::BaseController
      before_action :authenticate_user!, only: %i[]
      after_action -> { pagination_header(:trade_routes) }, only: [:index]

      def index
        authorize! :index, :api_trade_routes

        trade_routes_query_params['sorts'] = sort_by_name(['origin_shop_station_name asc', 'created_at desc'])

        @q = TradeRoute.with_profit.ransack(trade_routes_query_params)

        @trade_routes = @q.result
          .page(params[:page])
          .per(per_page(TradeRoute))
      end

      private def trade_routes_query_params
        @trade_routes_query_params ||= query_params(
          :cargo_ship,
          origin_station_in: [], destination_station_in: [], origin_celestial_object_in: [],
          destination_celestial_object_in: [], origin_starsystem_in: [],
          destination_starsystem_in: [], commodity_in: [], commodity_type_in: [],
          commodity_type_not_in: [], sorts: []
        )
      end
    end
  end
end
