# frozen_string_literal: true

module Api
  module V1
    class StationsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def index
        authorize! :index, :api_stations
        query_params['sorts'] = sort_by_name(['station_type asc', 'name asc'])

        @q = Station.visible
                    .ransack(query_params)

        @stations = @q.result
                      .page(params[:page])
                      .per(per_page(Station))
      end

      def show
        authorize! :show, :api_stations
        @station = Station.find_by!(slug: params[:slug])
      end
    end
  end
end
