# frozen_string_literal: true

module Api
  module V1
    class ShopCommoditiesController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:shop_commodities) }, only: [:index]

      def index
        authorize! :index, :api_shop_commodities
        sorts = [
          'model_name asc',
          'component_name asc',
          'commodity_name asc',
          'equipment_name asc',
          'model_module_name asc'
        ]
        shop_commodities_query_params['sorts'] = sort_by_name(sorts, sorts)

        @q = shop.shop_commodities
                 .ransack(shop_commodities_query_params)

        @shop_commodities = @q.result
                              .page(params[:page])
                              .per(per_page(ShopCommodity))
      end

      def sub_categories
        authorize! :index, :api_shop_commodities

        allowed_categories = nil
        if params[:shopSlug].present? && params[:stationSlug].present?
          station = Station.find_by(slug: params[:stationSlug])
          shop = Shop.find_by(slug: params[:shopSlug], station_id: station.id)
          allowed_categories = shop.shop_commodities.map(&:sub_category)
        end

        @filters = [
          Model.classification_filters.select { |item| !allowed_categories || allowed_categories.include?(item.value) },
          Equipment.type_filters.select { |item| !allowed_categories || allowed_categories.include?(item.value) },
          Component.class_filters.select { |item| !allowed_categories || allowed_categories.include?(item.value) }
        ].flatten.sort_by { |category| [category.category, category.name] }
      end

      private def shop
        @shop ||= station.shops.visible.find_by!(slug: params[:shop_slug])
      end

      private def station
        @station ||= Station.visible.find_by!(slug: params[:station_slug])
      end

      private def shop_commodities_query_params
        @shop_commodities_query_params ||= query_params(
          :name_cont, :price_gteq, :price_lteq,
          name_in: [], category_in: [], sub_category_in: [], manufacturer_in: []
        )
      end
    end
  end
end
