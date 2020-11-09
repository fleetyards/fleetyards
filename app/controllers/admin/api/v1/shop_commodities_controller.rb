# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ShopCommoditiesController < ::Admin::Api::BaseController
        after_action -> { pagination_header(:shop_commodities) }, only: [:index]

        def index
          authorize! :index, :admin_api_shop_commodities

          shop_commodities_query_params['sorts'] = 'created_at desc'

          scope = ShopCommodity

          scope = scipe.where(shop_id: shop.id) if shop.present?

          @q = scope
            .includes([:commodity_item])
            .ransack(shop_commodities_query_params)

          @shop_commodities = @q.result
            .page(params.fetch(:page, nil))
            .per(40)
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
            :commodity_item_id, :confirmed_eq
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
      end
    end
  end
end
