# frozen_string_literal: true

module Api
  module V1
    class TradeRoutesController < ::Api::BaseController
      before_action :authenticate_user!, only: %i[]
      after_action -> { pagination_header(:trade_routes) }, only: [:index]

      def index
        authorize! :index, :api_trade_routes

        trade_routes_query_params['sorts'] = sort_by_name(['profit_per_unit desc', 'created_at desc'])

        scope = TradeRoute.with_profit

        scope = filter_scope(scope, Station, :destination_station)
        scope = filter_scope(scope, CelestialObject, :destination_celestial_object)
        scope = filter_scope(scope, Starsystem, :destination_starsystem)
        scope = filter_scope(scope, Station, :origin_station)
        scope = filter_scope(scope, CelestialObject, :origin_celestial_object)
        scope = filter_scope(scope, Starsystem, :origin_starsystem)

        @q = scope.ransack(trade_routes_query_params)

        @trade_routes = @q.result
          .page(params[:page])
          .per(per_page(TradeRoute))
      end

      private def filter_scope(scope, klass, field)
        return scope if trade_routes_query_params["#{field}_in"].blank?

        ids = klass.where(slug: trade_routes_query_params["#{field}_in"]).pluck(:id)
        trade_routes_query_params.delete("#{field}_in")
        scope.where("#{field}_id": ids)
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
