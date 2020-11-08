# frozen_string_literal: true

module Admin
  module Api
    module V1
      class CommodityPricesController < ::Admin::Api::BaseController
        def create_sell_price
          authorize! :create, :admin_api_commodity_prices

          @commodity_price = CommoditySellPrice.new(commodity_price_params)

          return if commodity_price.save

          render json: ValidationError.new('commodity_price.create', commodity_price.errors), status: :bad_request
        end

        def create_buy_price
          authorize! :create, :admin_api_commodity_prices

          @commodity_price = CommodityBuyPrice.new(commodity_price_params)

          return if commodity_price.save

          render json: ValidationError.new('commodity_price.create', commodity_price.errors), status: :bad_request
        end

        def create_rental_price
          authorize! :create, :admin_api_commodity_prices

          @commodity_price = CommodityRentalPrice.new(commodity_price_params)

          return if commodity_price.save

          render json: ValidationError.new('commodity_price.create', commodity_price.errors), status: :bad_request
        end

        def destroy
          authorize! :destroy, commodity_price

          return if commodity_price.destroy

          render json: ValidationError.new('commodity_price.destroy', commodity_price.errors), status: :bad_request
        end

        def time_ranges
          authorize! :show, :admin_api_commodity_prices

          @filters = CommodityRentalPrice.time_range_filters

          render 'api/v1/shared/filters'
        end

        private def commodity_price
          @commodity_price ||= CommodityPrice.find(params[:id])
        end
        helper_method :commodity_price

        private def commodity_price_params
          @commodity_price_params ||= params.transform_keys(&:underscore)
            .permit(:shop_commodity_id, :price, :time_range).merge(confirmed: true)
        end
      end
    end
  end
end
