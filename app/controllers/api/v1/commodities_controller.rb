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
        # `with_facts` because the filters resolve against the joined build.
        # Without it a fact condition raises rather than quietly matching the
        # column, which is the failure mode to want here -- ransack drops a
        # condition it cannot place without saying a word.
        #
        # It also takes the flag rather than being paired with `current_version`:
        # for the default it inner-joins the build we are on, and that join
        # already leaves out what that build does not describe. Adding the scope
        # beside it scanned `commodity_builds` a second time for the same answer.
        @q = Commodity.with_facts(current_version)
          .includes(:item_prices)
          .ransack(commodities_query_params)

        @commodities = @q.result
          .page(params[:page])
          .per(per_page(Commodity))
      end

      # Taken out of the ransack params rather than left in them: it is a scope,
      # not a column, and ransack would try to match a `current_version` field.
      #
      # Memoized because the join and the scope both ask, and a `delete` with a
      # default answers the second caller with the default -- so
      # `currentVersion=false` picked the fallback join and was then filtered
      # back out by the scope.
      private def current_version
        return @current_version if defined?(@current_version)

        @current_version = commodities_query_params.delete(:current_version) { true }
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
