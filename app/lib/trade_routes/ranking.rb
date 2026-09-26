# frozen_string_literal: true

module TradeRoutes
  # Adds what a run earns for one ship to each route, and orders by it.
  #
  # The ship's capacity depends only on which crate sizes a route allows, and
  # the live routes share a couple of dozen such sets, so it is worked out once
  # per set in Ruby and handed to Postgres as a CASE. That keeps sorting and
  # pagination in the database.
  class Ranking
    SORT_EXPRESSIONS = {
      "profit_per_scu" => "(trade_routes.price_destination - trade_routes.price_origin)",
      "distance" => "trade_routes.distance",
      "profit_per_run" => "profit_per_run",
      "profit_per_distance" => "profit_per_distance"
    }.freeze

    def initialize(scope, capacity: nil)
      @scope = scope
      @capacity = capacity
    end

    def apply(sorts)
      @scope.select("trade_routes.*", *computed_columns).order(*order_clauses(sorts))
    end

    private def computed_columns
      return ["NULL::integer AS loadable_scu", "NULL::numeric AS profit_per_run", "NULL::numeric AS investment", "NULL::numeric AS profit_per_distance"] if @capacity.nil?

      loadable = "LEAST(#{ship_scu_sql}, trade_routes.scu_origin, trade_routes.scu_destination)"
      profit = "(#{loadable}) * (trade_routes.price_destination - trade_routes.price_origin)"

      [
        "#{loadable} AS loadable_scu",
        "#{profit} AS profit_per_run",
        "(#{loadable}) * trade_routes.price_origin AS investment",
        # A gateway hop reads as zero distance, which would otherwise divide
        # into an infinite ranking.
        "#{profit} / NULLIF(trade_routes.distance, 0) AS profit_per_distance"
      ]
    end

    private def ship_scu_sql
      sets = @scope.unscope(:select, :order).distinct.pluck("trade_routes.container_sizes")
      return "0" if sets.empty?

      whens = sets.map do |sizes|
        ActiveRecord::Base.sanitize_sql_array(["WHEN ?::integer[] THEN ?", PG::TextEncoder::Array.new.encode(sizes), @capacity.scu_for(sizes)])
      end

      "(CASE trade_routes.container_sizes #{whens.join(" ")} ELSE 0 END)"
    end

    private def order_clauses(sorts)
      clauses = sorts.filter_map do |sort|
        attribute, direction = sort.split
        expression = SORT_EXPRESSIONS[attribute]
        next if expression.nil?

        Arel.sql("#{expression} #{(direction == "asc") ? "ASC" : "DESC"} NULLS LAST")
      end

      clauses << Arel.sql("trade_routes.id")
    end
  end
end
