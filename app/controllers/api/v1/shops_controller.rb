# frozen_string_literal: true

module Api
  module V1
    class ShopsController < ::Api::PublicBaseController
      after_action -> { pagination_header(:shops) }, only: [:index]

      def index
        shop_query_params["sorts"] = sort_by_name

        @q = Shop.includes(station: {celestial_object: %i[starsystem parent]})
          .visible
          .ransack(shop_query_params)

        @shops = @q.result(distinct: true)
          .page(params[:page])
          .per(per_page(Shop))
      end

      def show
        @shop = station.shops.visible.find_by!(slug: params[:slug])
      end

      private def station
        @station ||= Station.visible.find_by!(slug: params[:station_slug])
      end

      private def shop_query_params
        @shop_query_params ||= query_params(
          :search_cont, :name_cont, :commodity_name_cont,
          name_in: [], model_in: [], equipment_in: [], component_in: [], commodity_in: [],
          shop_type_in: [], commodity_category_in: [], station_in: [], celestial_object_in: [],
          starsystem_in: []
        )
      end
    end
  end
end
