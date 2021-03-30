# frozen_string_literal: true

module Api
  module V1
    class CommodityPricesController < ::Api::BaseController
      before_action :authenticate_user!

      def create
        CommodityPrice.transaction do
          @commodity_price = CommodityPrice.new(commodity_price_params)

          authorize! :create, @commodity_price

          return if @commodity_price.save
        end

        render json: ValidationError.new('create', @commodity_price.errors), status: :bad_request
      end

      def time_ranges
        authorize! :read, :api_commodity_prices

        @filters = CommodityRentalPrice.time_range_filters

        render 'api/v1/shared/filters'
      end

      private def commodity_price_params
        @commodity_price_params ||= params.transform_keys(&:underscore).permit(
          :price, :time_range
        ).merge(
          confirmed: false,
          submitted_by: current_user.id,
          type: price_type,
          shop_commodity_id: shop_commodity.id
        )
      end

      private def price_type
        @price_type ||= case params[:path]
                        when 'buy'
                          'CommodityBuyPrice'
                        when 'rental'
                          'CommodityRentalPrice'
                        else # fallback to sell prices
                          'CommoditySellPrice'
                        end
      end

      private def shop_commodity
        @shop_commodity ||= ShopCommodity.find_or_create_by(
          shop_commodity_params
        ) do |new_shop_commodity|
          new_shop_commodity.submitted_by = current_user.id
          new_shop_commodity.confirmed = false
        end
      end

      private def shop_commodity_params
        @shop_commodity_params ||= params.transform_keys(&:underscore).permit(
          :shop_id, :commodity_item_id, :commodity_item_type
        )
      end
    end
  end
end
