# frozen_string_literal: true

module Api
  module V1
    class ShopCommoditiesController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:shop_commodities) }, only: [:index]

      def index
        authorize! :index, :api_shop_commodities
        sorts = [
          'commodity_item_of_Model_type_name asc',
          'commodity_item_of_Component_type_name asc',
          'commodity_item_of_Commodity_type_name asc',
          'commodity_item_of_Equipment_type_name asc'
        ]
        shop_commodities_query_params['sorts'] = sort_by_name(sorts, sorts)

        @q = shop.shop_commodities
                 .ransack(shop_commodities_query_params)

        @shop_commodities = @q.result
                              .page(params[:page])
                              .per(per_page(ShopCommodity))
      end

      def sub_categories
        authorize! :index, :api_models
        @sub_categories ||= begin
          sub_categories = []
          sub_categories << Model.classification_filters
          sub_categories << Equipment.type_filters
          sub_categories << Component.class_filters
          sub_categories.flatten
                        .sort_by { |category| [category.category, category.name] }
        end
      end

      private def shop
        @shop ||= station.shops.visible.find_by!(slug: params[:shop_slug])
      end

      private def station
        @station ||= Station.visible.find_by!(slug: params[:station_slug])
      end

      # rubocop:disable Metrics/MethodLength
      private def shop_commodities_query_params
        @shop_commodities_query_params ||= begin
          permitted_query_params = query_params(
            :name_cont, :min_price, :max_price,
            category_in: [], sub_category_in: [], manufacturer_slug_in: []
          )

          if permitted_query_params['name_cont'].present?
            key = %w[
              commodity_item_of_Model_type_name
              commodity_item_of_Component_type_name
              commodity_item_of_Commodity_type_name
              commodity_item_of_Equipment_type_name
            ].join('_or_')
            permitted_query_params["#{key}_cont"] = permitted_query_params.delete('name_cont')
          end

          if permitted_query_params['category_in'].present?
            permitted_query_params['commodity_item_type_in'] = permitted_query_params.delete('category_in')
          end

          if permitted_query_params['sub_category_in'].present?
            key = %w[
              commodity_item_of_Model_type_classification
              commodity_item_of_Component_type_component_class
              commodity_item_of_Equipment_type_equipment_type
            ].join('_or_')
            permitted_query_params["#{key}_in"] = permitted_query_params.delete('sub_category_in')
          end

          if permitted_query_params['manufacturer_slug_in'].present?
            key = %w[
              commodity_item_of_Model_type_manufacturer_slug
              commodity_item_of_Component_type_manufacturer_slug
              commodity_item_of_Equipment_type_manufacturer_slug
            ].join('_or_')
            permitted_query_params["#{key}_in"] = permitted_query_params.delete('manufacturer_slug_in')
          end

          if permitted_query_params['min_price'].present?
            permitted_query_params['sell_price_or_buy_price_or_rent_price_gteq'] = permitted_query_params.delete('min_price')
          end

          if permitted_query_params['max_price'].present?
            permitted_query_params['sell_price_or_buy_price_or_rent_price_lteq'] = permitted_query_params.delete('max_price')
          end

          permitted_query_params
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
