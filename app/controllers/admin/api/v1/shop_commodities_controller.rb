# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ShopCommoditiesController < ::Admin::Api::BaseController
        after_action -> { pagination_header(:shop_commodities) }, only: [:index]

        def index
          authorize! :index, :admin_api_shop_commodities

          Rails.logger.debug query_params.to_yaml
          @shop_commodities = ShopCommodity.search(
            search_params || '*',
            fields: [{ name: :word_start }],
            where: query_params.merge(price_params)
                               .merge(shop.present? ? { shop_id: shop.id } : {}),
            order: order_params,
            page: params[:page],
            per_page: per_page(ShopCommodity),
            includes: %i[shop commodity_item]
          )
        end

        def buy_prices
          authorize! :index, :admin_api_shop_commodities

          @prices = shop_commodity.commodity_buy_prices.order(created_at: :desc)
        end

        def sell_prices
          authorize! :index, :admin_api_shop_commodities

          @prices = shop_commodity.commodity_sell_prices.order(created_at: :desc)
        end

        def rental_prices
          authorize! :index, :admin_api_shop_commodities

          @prices = shop_commodity.commodity_rental_prices.order(time_range: :asc, created_at: :desc)
        end

        def create
          authorize! :create, :admin_api_shop_commodities

          @shop_commodity = ShopCommodity.new(shop_commodity_params)

          return if shop_commodity.save

          render json: ValidationError.new('shop_commodity.create', shop_commodity.errors), status: :bad_request
        end

        def confirm
          authorize! :update, shop_commodity

          return if shop_commodity.update(confirmed: true)

          render json: ValidationError.new('shop_commodity.update', shop_commodity.errors), status: :bad_request
        end

        def destroy
          authorize! :destroy, shop_commodity

          return if shop_commodity.destroy

          render json: ValidationError.new('shop_commodity.destroy', shop_commodity.errors), status: :bad_request
        end

        def update
          authorize! :update, shop_commodity

          return if shop_commodity.update(shop_commodity_params)

          render json: ValidationError.new('shop_commodity.update', shop_commodity.errors), status: :bad_request
        end

        private def shop
          @shop ||= Shop.find_by(id: params[:shop_id])
        end

        private def shop_commodities_query_params
          @shop_commodities_query_params ||= query_params(
            :commodity_item_id, :confirmed_eq, :name_cont, component_item_type_in: [], equipment_item_type_in: []
          )
        end

        private def shop_commodity_params
          @shop_commodity_params ||= params.transform_keys(&:underscore)
            .permit(:commodity_item_id, :commodity_item_type).merge(shop_id: shop.id, confirmed: true)
        end

        private def shop_commodity
          @shop_commodity ||= ShopCommodity.find(params[:id])
        end
        helper_method :shop_commodity

        private def search_params
          @search_params ||= params.permit(:search)[:search]
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

        private def price_params
          sell_price_range = {}
          buy_price_range = {}

          price_params = params.permit(query: %i[price_gteq price_lteq])

          sell_price_range[:gte] = price_params.dig(:filters, :price_gteq).to_f if price_params.dig(:filters, :price_gteq).present?
          sell_price_range[:lte] = price_params.dig(:filters, :price_lteq).to_f if price_params.dig(:filters, :price_lteq).present?

          buy_price_range[:gte] = price_params.dig(:filters, :price_gteq).to_f if price_params.dig(:filters, :price_gteq).present?
          buy_price_range[:lte] = price_params.dig(:filters, :price_lteq).to_f if price_params.dig(:filters, :price_lteq).present?

          price_params = {}

          price_params[:_or] = [] if sell_price_range.present? || buy_price_range.present?
          price_params[:_or].push({ sell_price: sell_price_range }) if sell_price_range.present?
          price_params[:_or].push({ buy_price: buy_price_range }) if buy_price_range.present?

          price_params
        end

        private def query_params
          @query_params ||= begin
            permitted_params = params.permit(
              filters: [
                {
                  name: [], manufacturer_slug: [], category: [], sub_category: [],
                  component_item_type: [], equipment_item_type: []
                }
              ]
            )

            permitted_params[:filters] || {}
          end
        end
      end
    end
  end
end
