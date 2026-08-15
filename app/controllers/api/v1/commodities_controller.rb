# frozen_string_literal: true

module Api
  module V1
    class CommoditiesController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index]

      after_action -> { pagination_header(:commodities) }, only: [:index]

      def index
        commodities_query_params["sorts"] = "name asc"

        @q = Commodity.ransack(commodities_query_params)

        @commodities = @q.result
          .page(params[:page])
          .per(per_page(Commodity))
      end

      private def commodities_query_params
        @commodities_query_params ||= params.permit(q: [
          :name_cont,
          id_in: [], name_in: [], slug_in: [], commodity_type_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
