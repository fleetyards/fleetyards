# frozen_string_literal: true

module Api
  module V1
    module Filters
      class TradeRoutesController < ::Api::PublicBaseController
        skip_verify_authorized

        before_action :check_trade_routes_feature

        def star_systems
          @filters = routed_terminals.where.not(star_system: nil).distinct.order(:star_system).pluck(:star_system).map do |star_system|
            Filter.new(category: "star_system", label: star_system, value: star_system)
          end

          render "api/v1/shared/filters"
        end

        def terminals
          @filters = routed_terminals.order(:name, :id).map do |terminal|
            Filter.new(category: terminal.star_system, label: terminal.name, value: terminal.id)
          end

          render "api/v1/shared/filters"
        end

        def commodities
          routed = TradeRoute.between_available_terminals.select(:commodity_id)

          @filters = Commodity.where(id: routed).includes(:build).sort_by(&:name).map do |commodity|
            Filter.new(category: "commodity", label: commodity.name, value: commodity.slug)
          end

          render "api/v1/shared/filters"
        end

        # Only terminals a route can actually be filtered down to.
        private def routed_terminals
          routes = TradeRoute.between_available_terminals

          Terminal.available.where(id: routes.select(:origin_terminal_id))
            .or(Terminal.available.where(id: routes.select(:destination_terminal_id)))
        end

        private def check_trade_routes_feature
          return if feature_enabled?("trade_routes")

          render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
        end
      end
    end
  end
end
