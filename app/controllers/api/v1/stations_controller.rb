# frozen_string_literal: true

module Api
  module V1
    class StationsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:stations) }, only: [:index]

      def index
        authorize! :index, :api_stations
        station_query_params['sorts'] = sort_by_name(['station_type asc', 'name asc'])

        @q = Station.visible
                    .ransack(station_query_params)

        @stations = @q.result
                      .page(params[:page])
                      .per(per_page(Station))
      end

      def show
        authorize! :show, :api_stations
        @station = Station.visible.find_by!(slug: params[:slug])
      end

      private def station_query_params
        @station_query_params ||= query_params(
          :celestial_object_slug_eq
        )
      end
    end
  end
end
