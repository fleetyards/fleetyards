# frozen_string_literal: true

module Api
  module V1
    class SearchController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: %i[]

      def index
        authorize! :index, :api_search

        @results = Searchkick.search(
          params[:search],
          models: [Model, ShopCommodity, Shop, Station, CelestialObject, Starsystem],
          fields: ['name^5', 'manufacturer_name', 'station', 'shop', 'celestial_object', 'starsystem', 'shop_type', 'station_type'],
          page: params[:page],
          per_page: 30
        )
      end
    end
  end
end
