# frozen_string_literal: true

module Admin
  module Api
    module V1
      class StationsController < ::Admin::Api::BaseController
        after_action -> { pagination_header(:stations) }, only: [:index]
        after_action -> { pagination_header(:images) }, only: [:images]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t('messages.record_not_found.station', slug: params[:slug]))
        end

        def index
          authorize! :index, :admin_api_stations

          station_query_params['sorts'] = sort_by_name(['station_type asc', 'name asc'])

          @q = Station.visible
                      .ransack(station_query_params)

          @stations = @q.result(distinct: true)
                        .page(params[:page])
                        .per(per_page(Station))
        end

        def options
          authorize! :options, :admin_api_stations
          station_query_params['sorts'] = sort_by_name(['station_type asc', 'name asc'])

          @q = Station.visible
                      .ransack(station_query_params)

          @stations = @q.result(distinct: true)
                        .page(params[:page])
                        .per(per_page(Station))
        end

        def images
          authorize! :show, :admin_api_stations
          station = Station.find(params[:id])
          @images = station.images
                           .order('images.created_at desc')
                           .page(params[:page])
                           .per(per_page(Image))
        end

        private def station_query_params
          @station_query_params ||= query_params(
            :name_cont, name_in: []
          )
        end
      end
    end
  end
end
