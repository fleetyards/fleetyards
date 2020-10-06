# frozen_string_literal: true

module Api
  module V1
    class ShopsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:shops) }, only: [:index]

      def show
        authorize! :show, :api_shops
        @shop = station.shops.visible.find_by!(slug: params[:slug])
      end

      def index
        authorize! :index, :api_shops

        shop_query_params['sorts'] = sort_by_name

        @q = Shop.includes(station: { celestial_object: %i[starsystem parent] })
          .visible
          .ransack(shop_query_params)

        @shops = @q.result(distinct: true)
          .page(params[:page])
          .per(per_page(Shop))
      end

      def shop_types
        authorize! :show, :api_shops

        @filters = Shop.type_filters

        render 'api/v1/shared/filters'
      end

      private def station
        @station ||= Station.visible.find_by!(slug: params[:station_slug])
      end

      private def shop_query_params
        @shop_query_params ||= query_params(
          :name_cont, :commodity_name_cont,
          name_in: [], model_in: [], equipment_in: [], component_in: [], commodity_in: [],
          shop_type_in: [], commodity_category_in: [], station_in: [], celestial_object_in: [],
          starsystem_in: []
        )
      end
    end
  end
end
