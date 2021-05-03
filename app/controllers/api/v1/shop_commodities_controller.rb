# frozen_string_literal: true

module Api
  module V1
    class ShopCommoditiesController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:shop_commodities) }, only: [:index]

      def index
        authorize! :index, :api_shop_commodities

        @shop_commodities = ShopCommodity.search(
          search_params || deprecated_search_params || '*',
          fields: [{ name: :word_start }],
          where: deprecated_query_params.merge(query_params)
                                        .merge(price_params)
                                        .merge({ shop_id: shop.id }),
          order: order_params,
          page: params[:page],
          per_page: per_page(ShopCommodity),
          includes: %i[shop commodity_item]
        )
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def sub_categories
        authorize! :index, :api_shop_commodities

        allowed_categories = nil

        if params[:shopSlug].present? && params[:stationSlug].present?
          station = Station.find_by(slug: params[:stationSlug])
          shop = Shop.find_by(slug: params[:shopSlug], station_id: station.id)
          allowed_categories = shop.shop_commodities.includes(:commodity_item).map(&:sub_category)
        end

        @filters = [
          Model.classification_filters.select { |item| !allowed_categories || allowed_categories.include?(item.value) },
          Equipment.type_filters.select { |item| !allowed_categories || allowed_categories.include?(item.value) },
          Component.class_filters.select { |item| !allowed_categories || allowed_categories.include?(item.value) }
        ].flatten.sort_by { |category| [category.category, category.name] }
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def commodity_item_types
        authorize! :index, :api_shop_commodities

        @commodity_item_types = ShopCommodity.commodity_item_types.map do |item_type|
          {
            name: I18n.t("activerecord.attributes.shop_commodity.commodity_item_types.#{item_type}"),
            value: item_type,
          }
        end.sort_by { |item| item[:name] }
      end

      private def shop
        @shop ||= station.shops.visible.find_by!(slug: params[:shop_slug])
      end

      private def station
        @station ||= Station.visible.find_by!(slug: params[:station_slug])
      end

      private def search_params
        @search_params ||= params.permit(:search)[:search]
      end

      private def deprecated_search_params
        @deprecated_search_params ||= params.permit(q: [:name_cont]).dig(:q, :name_cont)
      end

      private def order_params
        @order_params ||= begin
          permitted_params = params.permit(
            order: [
              :name
            ]
          )

          permitted_params[:order] || { 'name' => 'asc', 'created_at' => 'asc' }
        end
      end

      private def deprecated_query_params
        @deprecated_query_params ||= begin
          permitted_params = params.permit(q: [nameIn: [], categoryIn: [], subCategoryIn: [], manufacturerIn: []])

          query_params = {}

          query_params[:name] = permitted_params.dig(:q, :nameIn) if permitted_params.dig(:q, :nameIn).present?
          query_params[:category] = permitted_params.dig(:q, :categoryIn) if permitted_params.dig(:q, :categoryIn).present?
          query_params[:sub_category] = permitted_params.dig(:q, :subCategoryIn) if permitted_params.dig(:q, :subCategoryIn).present?
          query_params[:manufacturer] = permitted_params.dig(:q, :manufacturerIn) if permitted_params.dig(:q, :manufacturerIn).present?

          query_params
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      private def price_params
        deprecated_price_params = params.permit(q: %i[priceGteq priceLteq])

        sell_price_range = {}
        buy_price_range = {}

        sell_price_range[:gte] = deprecated_price_params.dig(:q, :priceGteq).to_f if deprecated_price_params.dig(:q, :priceGteq).present?
        sell_price_range[:lte] = deprecated_price_params.dig(:q, :priceLteq).to_f if deprecated_price_params.dig(:q, :priceLteq).present?

        buy_price_range[:gte] = deprecated_price_params.dig(:q, :priceGteq).to_f if deprecated_price_params.dig(:q, :priceGteq).present?
        buy_price_range[:lte] = deprecated_price_params.dig(:q, :priceLteq).to_f if deprecated_price_params.dig(:q, :priceLteq).present?

        price_params = params.permit(query: %i[price_gteq price_lteq])

        sell_price_range[:gte] = price_params.dig(:query, :price_gteq).to_f if price_params.dig(:query, :price_gteq).present?
        sell_price_range[:lte] = price_params.dig(:query, :price_lteq).to_f if price_params.dig(:query, :price_lteq).present?

        buy_price_range[:gte] = price_params.dig(:query, :price_gteq).to_f if price_params.dig(:query, :price_gteq).present?
        buy_price_range[:lte] = price_params.dig(:query, :price_lteq).to_f if price_params.dig(:query, :price_lteq).present?

        price_params = {}

        price_params[:_or] = [] if sell_price_range.present? || buy_price_range.present?
        price_params[:_or].push({ sell_price: sell_price_range }) if sell_price_range.present?
        price_params[:_or].push({ buy_price: buy_price_range }) if buy_price_range.present?

        price_params
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      private def query_params
        @query_params ||= begin
          permitted_params = params.permit(
            query: [{
              name: [], manufacturer_slug: [], category: [], sub_category: []
            }]
          )

          permitted_params[:query] || {}
        end
      end
    end
  end
end
