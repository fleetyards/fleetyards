# frozen_string_literal: true

module Admin
  module Api
    module V1
      # Shops come and go with the UEX feed; only their picture is edited here.
      # Under the locations privilege, since a shop is a part of its place.
      class ShopsController < ::Admin::Api::BaseController
        before_action :set_shop

        def show
        end

        def update
          return render :show if @shop.update(shop_params)

          render json: ValidationError.new("shop.update", errors: @shop.errors), status: :bad_request
        end

        private def set_shop
          @shop = Shop.includes(:location).find(params[:id])

          authorize! @shop, with: ::Admin::LocationPolicy
        end

        private def shop_params
          params.permit(:image)
        end
      end
    end
  end
end
