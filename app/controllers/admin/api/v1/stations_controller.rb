# frozen_string_literal: true

module Admin
  module Api
    module V1
      class StationsController < ::Admin::Api::BaseController
        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t('messages.record_not_found.station', slug: params[:slug]))
        end

        def images
          authorize! :show, :admin_api_stations
          station = Station.find(params[:id])
          @images = station.images
                           .order('images.created_at desc')
        end
      end
    end
  end
end
