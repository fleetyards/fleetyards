# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ItemPricesController < ::Admin::Api::BaseController
        before_action :set_item_price, only: %i[show update destroy]

        def index
          authorize! :index, :admin_api_item_prices

          item_price_query_params["sorts"] = "created_at desc"

          @q = ItemPrice.ransack(item_price_query_params)

          @item_prices = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          authorize! :create, :admin_api_item_prices

          @item_price = ItemPrice.new(item_price_params)

          if @item_price.save
            render :show, status: :created
          else
            render json: ValidationError.new("item_price.create", errors: @item_price.errors), status: :bad_request
          end
        end

        def show
          authorize! :show, :admin_api_item_prices
        end

        def update
          authorize! :update, :admin_api_item_prices

          if @item_price.update(item_price_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("item_price.update", errors: @item_price.errors), status: :bad_request
          end
        end

        def destroy
          authorize! :destroy, :admin_api_item_prices

          @item_price.destroy

          head :no_content
        end

        private def set_item_price
          @item_price = ItemPrice.find(params[:id])
        end

        private def item_price_params
          @item_price_params ||= params.permit(
            :item_id, :item_type, :price, :price_type, :location, :location_url
          )
        end

        private def item_price_query_params
          @item_price_query_params ||= query_params(
            :item_id_eq, :item_type_eq, :location_cont, :sorts, item_id_in: [], item_type_in: []
          )
        end
      end
    end
  end
end
