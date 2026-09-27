# frozen_string_literal: true

module Api
  module V1
    class TradeRoutesController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index]

      before_action :check_trade_routes_feature

      after_action -> { pagination_header(:trade_routes) }, only: [:index]

      def index
        normalize_sort_params(trade_routes_query_params)
        sorts = sorting_params(TradeRoute, trade_routes_query_params.delete("sorts"), allowed: allowed_sorts)
        budget = trade_routes_query_params.delete(:budget).presence&.to_d
        max_price_age = trade_routes_query_params.delete(:max_price_age_hours).presence&.to_i
        grouped = ActiveModel::Type::Boolean.new.cast(trade_routes_query_params.delete(:grouped))

        scope = TradeRoute.between_available_terminals
        scope = scope.priced_within(max_price_age.hours) if max_price_age&.positive?

        @q = scope.includes(:origin_terminal, :destination_terminal, commodity: :build)
          .ransack(trade_routes_query_params)

        @grouped = grouped
        @trade_routes = ::TradeRoutes::Ranking.new(@q.result, capacity: ship_capacity, budget:)
          .apply(sorts, grouped:)
          .page(page_params)
          .per(per_page(TradeRoute))
      end

      private def allowed_sorts
        return TradeRoute::ALLOWED_SORTING_PARAMS if ship_capacity.present?

        TradeRoute::ALLOWED_SORTING_PARAMS - TradeRoute::SHIP_SORTING_PARAMS
      end

      private def ship_capacity
        return @ship_capacity if defined?(@ship_capacity)

        slug = trade_routes_query_params.delete(:model_slug)
        model = Model.visible.active.find_by(slug: slug.to_s.downcase) if slug.present?

        @ship_capacity = model && ::TradeRoutes::ShipCapacity.new(model)
      end

      private def trade_routes_query_params
        @trade_routes_query_params ||= params.permit(q: [
          :s, :sorts, :model_slug, :budget, :max_price_age_hours, :grouped,
          sorts: [], commodity_id_in: [], commodity_slug_in: [],
          origin_terminal_id_in: [], destination_terminal_id_in: [],
          origin_terminal_star_system_in: [], destination_terminal_star_system_in: []
        ]).fetch(:q, {})
      end

      private def check_trade_routes_feature
        return if feature_enabled?("trade_routes")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
