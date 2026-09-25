# frozen_string_literal: true

module Api
  module V1
    class CommoditiesController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index show price_history]

      after_action -> { pagination_header(:commodities) }, only: [:index]

      # How far back the chart reaches. Two years are retained, but a commodity
      # chart people read to trade on is about the last few months.
      PRICE_HISTORY_WINDOW = 90.days

      def index
        # The model has named its allowed sorts all along; this action threw them
        # away and forced `name asc` on every request. `sorting_params` is what
        # every other list endpoint uses, and it falls back to the model's
        # default rather than trusting whatever arrives. `normalize_sort_params`
        # first, because a sortable list sends `q[s]` and ransack would read a
        # leftover `s` ahead of the whitelisted `sorts`.
        normalize_sort_params(commodities_query_params)
        commodities_query_params["sorts"] = sorting_params(Commodity, commodities_query_params["sorts"])

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
          .includes(:item_prices, :refines_into)
          .ransack(commodities_query_params)

        @commodities = @q.result
          .page(page_params)
          .per(per_page(Commodity))
      end

      # Unscoped by build, unlike the list: a link to a commodity the current
      # patch has dropped has to keep resolving, because the ledger keeps its
      # rows so old inventory entries still read. `retired` in the payload is
      # what says which one the reader is looking at.
      def show
        # `item_prices` for the two price figures and the terminals, which
        # `ItemPriceConcern` reads off the loaded association rather than
        # querying per call.
        @commodity = Commodity.includes(:item_prices, :refines_into)
          .find_by!(slug: params[:slug].to_s.downcase)

        # Only the forms the build we are on still describes: a dropped ore
        # would link to a page that says it no longer exists. The inner join to
        # that build is the filter, and ordering by its name keeps the sort on
        # the names the payload shows -- `name` reads through the build, which
        # is also why it is preloaded.
        @refined_from = @commodity.refined_from.with_facts
          .includes(:build).order(Commodity.fact_sql(:name))
      end

      def price_history
        commodity = Commodity.find_by!(slug: params[:slug].to_s.downcase)

        # One row per day and direction, folded into a row per day below. Doing
        # the aggregation in Postgres keeps a 90-day window at a few hundred
        # rows rather than every snapshot the commodity has.
        per_day_and_direction = ItemPriceSnapshot
          .where(item_type: "Commodity", item_id: commodity.id)
          .recorded_since(PRICE_HISTORY_WINDOW.ago.to_date)
          .group(:recorded_on, :price_type)
          .pluck(
            :recorded_on,
            :price_type,
            Arel.sql("MIN(price)"),
            Arel.sql("AVG(price)"),
            Arel.sql("MAX(price)")
          )

        @price_history = fold_price_history(per_day_and_direction)
      end

      # `sell` is the shop selling, which is where a player buys -- the same
      # perspective `soldAt` and `boughtAt` already use on the item itself.
      private def fold_price_history(rows)
        days = Hash.new { |result, day| result[day] = {recorded_on: day} }

        rows.each do |day, price_type, lowest, average, highest|
          # `pluck` casts an enum back to its name, so this compares strings.
          prefix = (price_type.to_s == "sell") ? :sold : :bought

          days[day][:"#{prefix}_lowest"] = lowest
          days[day][:"#{prefix}_average"] = average&.round(2)
          days[day][:"#{prefix}_highest"] = highest
        end

        days.values.sort_by { |day| day[:recorded_on] }
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
        # The price predicates resolve against the `buy_price`/`sell_price`
        # ransackers, which are typed `:decimal` so a range compares numbers
        # rather than the strings a query string carries. `_not_null` is the
        # "traded anywhere we know of" filter: 124 of the 232 have a price row,
        # and the rest are not a smaller number, they are a different question.
        @commodities_query_params ||= params.permit(q: [
          :s, :sorts, :name_cont, :description_cont, :current_version,
          :buy_price_gteq, :buy_price_lteq, :buy_price_not_null,
          :sell_price_gteq, :sell_price_lteq, :sell_price_not_null,
          sorts: [], id_in: [], name_in: [], slug_in: [], commodity_type_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
