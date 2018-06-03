# frozen_string_literal: true

module Api
  module V1
    class StationsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def index
        authorize! :index, :api_stations
        @q = Station.visible
                    .ransack(query_params)

        @q.sorts = 'name asc' if @q.sorts.empty?

        @stations = @q.result.offset(params[:offset]).limit(params[:limit])
      end

      def show
        authorize! :show, :api_stations
        @station = Station.find_by!(slug: params[:slug])
      end
    end
  end
end
