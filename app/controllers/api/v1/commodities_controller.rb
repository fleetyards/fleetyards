# frozen_string_literal: true

module Api
  module V1
    class CommoditiesController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index]

      after_action -> { pagination_header(:commodities) }, only: [:index]

      def index
        commodities_query_params["sorts"] = "name asc"

        # Commodities a later patch stopped shipping are left out unless
        # currentVersion=false asks for them -- the rows stay so old ledger
        # entries still resolve, they are just not offered for new ones.
        @q = Commodity.current_version(current_version).includes(:item_prices).ransack(commodities_query_params)

        @commodities = @q.result
          .page(params[:page])
          .per(per_page(Commodity))
      end

      # Taken out of the ransack params rather than left in them: it is a scope,
      # not a column, and ransack would try to match a `current_version` field.
      private def current_version
        commodities_query_params.delete(:current_version) { true }
      end

      private def commodities_query_params
        @commodities_query_params ||= params.permit(q: [
          :name_cont, :current_version,
          id_in: [], name_in: [], slug_in: [], commodity_type_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
