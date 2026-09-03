# frozen_string_literal: true

module Api
  module V1
    class CommoditiesController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index price_history]

      after_action -> { pagination_header(:commodities) }, only: [:index]

      # How far back the chart reaches. Two years are retained, but a commodity
      # chart people read to trade on is about the last few months.
      PRICE_HISTORY_WINDOW = 90.days

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
        @commodities_query_params ||= params.permit(q: [
          :name_cont, :current_version,
          id_in: [], name_in: [], slug_in: [], commodity_type_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
