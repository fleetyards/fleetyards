# frozen_string_literal: true

module Api
  module V1
    class CommodityPricesController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def show
        authorize! :show, :api_commodity_prices

        @commodity_price = CommodityPrice.find(params[:id])
      end

      def create
        authorize! :create, :api_commodity_prices

        @commodity_price = CommodityPrice.find_or_create_by(key: key) do |price|
          price.data = JSON.parse(price_params[:data])
        end
        if @commodity_price.valid?
          render status: :created
        else
          render json: { code: 'commodity-price.create', message: I18n.t('messages.commodity-price.create.failure') }, status: :bad_request
        end
      rescue JSON::ParserError
        render json: { code: 'commodity-price.create', message: I18n.t('messages.commodity-price.create.failure') }, status: :bad_request
      end

      private def price_params
        @price_params ||= params.permit(:data)
      end

      private def key
        return if price_params[:data].blank?
        @key = Digest::SHA512.hexdigest(price_params[:data])
      end
    end
  end
end
