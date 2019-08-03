# frozen_string_literal: true

module Api
  module V1
    class StationsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:stations) }, only: [:index]
      after_action -> { pagination_header(:images) }, only: [:images]

      def index
        authorize! :index, :api_stations
        station_query_params['sorts'] = sort_by_name(['station_type asc', 'name asc'])

        @q = Station.visible
                    .ransack(station_query_params)

        @stations = @q.result(distinct: true)
                      .page(params[:page])
                      .per(per_page(Station))
      end

      def show
        authorize! :show, :api_stations
        @station = Station.visible.find_by!(slug: params[:slug])
      end

      def ship_sizes
        authorize! :show, :api_stations

        @filters = Dock.size_filters

        render 'api/v1/shared/filters'
      end

      def station_types
        authorize! :show, :api_stations

        @filters = Station.type_filters

        render 'api/v1/shared/filters'
      end

      def images
        authorize! :show, :api_models
        station = Station.visible.find_by!(slug: params[:slug])
        @images = station.images
                         .enabled
                         .order('images.created_at desc')
                         .page(params[:page])
                         .per(per_page(Image))
      end


      private def station_query_params
        @station_query_params ||= query_params(
          :celestial_object_eq, :name_cont, :habs_not_null,
          celestial_object_in: [], starsystem_in: [], station_type_in: [],
          shops_shop_type_in: [], docks_ship_size_in: []
        )
      end
    end
  end
end
