# frozen_string_literal: true

module Api
  module V1
    class StationsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:stations) }, only: [:index]
      after_action -> { pagination_header(:images) }, only: [:images]

      def index
        authorize! :index, :api_stations
        station_query_params['sorts'] = sort_by_name if station_query_params['sorts'].blank?

        scope = Station.visible.includes(:docks, :habitations, :shops, celestial_object: %i[starsystem parent])

        scope = scope.with_shops(commodity_item_type: station_query_params.delete(:commodity_item_type)) if station_query_params.delete(:with_shops)

        @q = scope.ransack(station_query_params)

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

      def classifications
        authorize! :show, :api_stations

        @filters = Station.classification_filters

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
          :with_shops, :celestial_object_eq, :name_cont, :slug_eq, :habs_not_null, :search_cont,
          :commodity_item_type, :cargo_hub_eq, :refinery_eq,
          name_in: [], celestial_object_in: [], starsystem_in: [], station_type_in: [],
          shops_shop_type_in: [], docks_ship_size_in: [], sorts: []
        )
      end
    end
  end
end
