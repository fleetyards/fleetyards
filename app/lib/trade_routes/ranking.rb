# frozen_string_literal: true

module TradeRoutes
  # Adds what a run earns for one ship to each route, and orders by it.
  #
  # The ship's capacity depends only on which crate sizes a route allows, and
  # the live routes share a couple of dozen such sets, so it is worked out once
  # per set in Ruby and handed to Postgres as a CASE. That keeps sorting and
  # pagination in the database.
  class Ranking
    def initialize(scope, capacity: nil, budget: nil)
      @scope = scope
      @capacity = capacity
      @budget = budget&.positive? ? budget : nil
    end

    # Grouped, each commodity bought at one terminal appears once, with its best
    # destination by the requested sort, and `group_size` counts the others.
    def apply(sorts, grouped: false)
      sorts = sorts.filter_map { |sort| parse_sort(sort) }
      relation = @scope.select("trade_routes.*", *computed_columns)

      return relation.order(*order_clauses(sorts, raw: true)) unless grouped

      ranked = relation.select(
        "ROW_NUMBER() OVER (PARTITION BY trade_routes.commodity_id, trade_routes.origin_terminal_id " \
        "ORDER BY #{order_clauses(sorts, raw: true).join(", ")}) AS group_rank",
        "COUNT(*) OVER (PARTITION BY trade_routes.commodity_id, trade_routes.origin_terminal_id) AS group_size"
      )

      TradeRoute.unscoped
        .from(ranked.unscope(:order, :includes, :preload, :eager_load), :trade_routes)
        .select("trade_routes.*")
        .where("trade_routes.group_rank = 1")
        .preload(@scope.includes_values)
        .order(*order_clauses(sorts, raw: false))
    end

    private def parse_sort(sort)
      attribute, direction = sort.split
      return unless sort_expression(attribute, raw: true)

      [attribute, (direction == "asc") ? "ASC" : "DESC"]
    end

    # `raw` for the expression itself, which the window function needs; the
    # outer query of a grouped list reads the columns the inner one computed.
    private def sort_expression(attribute, raw:)
      case attribute
      when "profit_per_scu" then "(trade_routes.price_destination - trade_routes.price_origin)"
      when "distance" then "trade_routes.distance"
      when "profit_per_run" then raw ? profit_sql : "trade_routes.profit_per_run"
      when "profit_per_distance" then raw ? profit_per_distance_sql : "trade_routes.profit_per_distance"
      end
    end

    private def order_clauses(sorts, raw:)
      clauses = sorts.map do |attribute, direction|
        "#{sort_expression(attribute, raw:)} #{direction} NULLS LAST"
      end

      (clauses + ["trade_routes.distance ASC NULLS LAST", "trade_routes.id"]).map { |clause| Arel.sql(clause) }
    end

    private def computed_columns
      if @capacity.nil?
        return [
          "NULL::integer AS loadable_scu", "NULL::varchar AS load_limit", "NULL::numeric AS profit_per_run",
          "NULL::numeric AS investment", "NULL::numeric AS profit_per_distance"
        ]
      end

      [
        "#{loadable_sql} AS loadable_scu",
        "#{load_limit_sql} AS load_limit",
        "#{profit_sql} AS profit_per_run",
        "(#{loadable_sql}) * trade_routes.price_origin AS investment",
        "#{profit_per_distance_sql} AS profit_per_distance"
      ]
    end

    private def limits
      @limits ||= {
        "hold" => ship_scu_sql,
        "stock" => "trade_routes.scu_origin",
        "demand" => "trade_routes.scu_destination",
        "budget" => @budget && ActiveRecord::Base.sanitize_sql_array(["FLOOR(?::numeric / trade_routes.price_origin)::integer", @budget])
      }.compact
    end

    private def loadable_sql
      "LEAST(#{limits.values.join(", ")})"
    end

    # The first bound the load meets, checked in the order a pilot reads them:
    # a full hold is the good news, the rest say what to change.
    private def load_limit_sql
      whens = limits.keys[0..-2].map.with_index do |name, index|
        rest = limits.values[(index + 1)..]
        "WHEN #{limits[name]} <= LEAST(#{rest.join(", ")}) THEN '#{name}'"
      end

      "(CASE #{whens.join(" ")} ELSE '#{limits.keys.last}' END)"
    end

    private def profit_sql
      "((#{loadable_sql}) * (trade_routes.price_destination - trade_routes.price_origin))"
    end

    # A gateway hop reads as zero distance, which would otherwise divide into
    # an infinite ranking.
    private def profit_per_distance_sql
      "(#{profit_sql} / NULLIF(trade_routes.distance, 0))"
    end

    private def ship_scu_sql
      @ship_scu_sql ||= begin
        sets = @scope.unscope(:select, :order, :includes, :preload).distinct.pluck("trade_routes.container_sizes")

        if sets.empty?
          "0"
        else
          whens = sets.map do |sizes|
            ActiveRecord::Base.sanitize_sql_array(["WHEN ?::integer[] THEN ?", PG::TextEncoder::Array.new.encode(sizes), @capacity.scu_for(sizes)])
          end

          "(CASE trade_routes.container_sizes #{whens.join(" ")} ELSE 0 END)"
        end
      end
    end
  end
end
