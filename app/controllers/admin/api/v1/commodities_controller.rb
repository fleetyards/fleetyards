# frozen_string_literal: true

module Admin
  module Api
    module V1
      class CommoditiesController < ::Admin::Api::BaseController
        before_action :set_commodity, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::CommodityPolicy

          commodity_query_params["sorts"] = sorting_params(Commodity, commodity_query_params[:sorts])

          @q = authorized_scope(Commodity.all).includes(:item_prices).ransack(commodity_query_params)

          @commodities = @q.result
            .page(params[:page])
            .per(per_page(Commodity))
        end

        def show
        end

        def create
          @commodity = Commodity.new(commodity_params)

          authorize! @commodity, with: ::Admin::CommodityPolicy

          return if @commodity.save

          render json: ValidationError.new("commodity.create", errors: @commodity.errors), status: :bad_request
        end

        def update
          return if @commodity.update(commodity_params)

          render json: ValidationError.new("commodity.update", errors: @commodity.errors), status: :bad_request
        end

        def destroy
          return if @commodity.destroy

          render json: ValidationError.new("commodity.destroy", errors: @commodity.errors), status: :bad_request
        end

        # Authorized rather than merely signed-in: it is declared in the schema
        # and reached by a generated client, so it answers 401/403 like the rest
        # of the resource.
        def type_filters
          authorize! with: ::Admin::CommodityPolicy

          @filters = Commodity.type_filters

          render "api/shared/filters"
        end

        private def set_commodity
          @commodity = Commodity.find(params[:id])

          authorize! @commodity, with: ::Admin::CommodityPolicy
        end

        private def commodity_params
          @commodity_params ||= params.permit(
            :name, :description, :commodity_type, :uex_id, :uex_code,
            :store_image, :sc_key, :sc_ref
          )
        end

        private def commodity_query_params
          @commodity_query_params ||= params.permit(q: [
            :name_cont, :name_eq, :id_eq, :commodity_type_eq, :commodity_type_cont,
            :uex_code_cont, :store_image_blank, :buy_price_gteq, :buy_price_lteq, :sell_price_gteq,
            :sell_price_lteq, :sorts,
            sorts: [], name_in: [], id_in: [], commodity_type_in: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
