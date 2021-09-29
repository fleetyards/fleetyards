# frozen_string_literal: true

module Api
  module V1
    class CommodityPricesController < ::Api::BaseController
      before_action :authenticate_user!, only: [:create]

      def create
        @commodity_price = CommodityPrice.find_or_initialize_by(
          type: commodity_price_params[:type],
          shop_commodity_id: commodity_price_params[:shop_commodity_id],
          confirmed: false,
          price: commodity_price_params[:price],
          time_range: commodity_price_params[:time_range]
        ) do |price|
          price.submitters << current_user.id
        end

        authorize! :create, @commodity_price

        if @commodity_price.new_record?
          return if @commodity_price.save

          render json: ValidationError.new('commodity_price.create', errors: @commodity_price.errors), status: :bad_request
        elsif @commodity_price.submitters.exclude?(current_user.id)
          @commodity_price.update(
            submitters: @commodity_price.submitters << current_user.id,
            submission_count: @commodity_price.submission_count + 1
          )
        end
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
          type: price_type,
          shop_commodity_id: shop_commodity&.id
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
        return if shop_commodity_params.blank?

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
