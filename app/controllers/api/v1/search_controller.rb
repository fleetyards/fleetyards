# frozen_string_literal: true

module Api
  module V1
    class SearchController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: %i[]
      after_action -> { pagination_header(:results) }, only: [:index]

      def index
        authorize! :index, :api_search

        @results = Searchkick.search(
          search_query_params[:search],
          models: [Model, ShopCommodity, Shop, Station, CelestialObject, Starsystem],
          fields: [
            'name^5', 'manufacturer_name', 'manufacturer_code', 'station', 'shop',
            'celestial_object', 'starsystem', 'shop_type', 'station_type'
          ],
          indices_boost: {
            Model => 10,
            Station => 8,
            CelestialObject => 6,
            Starsystem => 6,
            Shop => 4,
            ShopCommodity => 1
          },
          misspellings: { below: 5 },
          page: params[:page],
          per_page: 30
        )
      end

      private def search_query_params
        @search_query_params ||= query_params(:search)
      end
    end
  end
end
