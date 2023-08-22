# frozen_string_literal: true

module Admin
  module Api
    module V1
      class StationsController < ::Admin::Api::BaseController
        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.station", slug: params[:slug]))
        end

        def index
          authorize! :index, :admin_api_stations

          station_query_params["sorts"] = sorting_params(Station)

          q = Station.visible
            .ransack(station_query_params)

          @stations = q.result(distinct: true)
            .page(params[:page])
            .per(per_page(Station))
        end

        def options
          authorize! :options, :admin_api_stations
          station_query_params["sorts"] = sorting_params(Station)

          @q = Station.visible
            .ransack(station_query_params)

          @stations = @q.result(distinct: true)
            .page(params[:page])
            .per(per_page(Station))
        end

        private def station_query_params
          @station_query_params ||= query_params(
            :search_cont, :name_cont, :id_eq, id_in: [], name_in: []
          )
        end
      end
    end
  end
end
