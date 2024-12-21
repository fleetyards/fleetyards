# frozen_string_literal: true

module Api
  module V1
    class CommoditiesController < ::Api::PublicBaseController
      after_action -> { pagination_header(:commodities) }, only: [:index]

      def index
        commodity_query_params["sorts"] = "name asc"

        @q = Commodity.ransack(commodity_query_params)

        @commodities = @q.result
          .page(params[:page])
          .per(per_page(Commodity))
      end

      private def commodity_query_params
        @commodity_query_params ||= query_params(:name_cont, id_in: [], name_in: [])
      end
    end
  end
end
