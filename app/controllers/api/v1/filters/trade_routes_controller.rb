# frozen_string_literal: true

module Api
  module V1
    module Filters
      class TradeRoutesController < ::Api::PublicBaseController
        skip_verify_authorized

        def star_systems
          @filters = routed_terminals.where.not(star_system: nil).distinct.order(:star_system).pluck(:star_system).map do |star_system|
            Filter.new(category: "star_system", label: star_system, value: star_system)
          end

          render "api/v1/shared/filters"
        end

        def terminals
          render_terminals(routed_terminals)
        end

        def origin_terminals
          render_terminals(terminals_on(:origin_terminal_id))
        end

        def destination_terminals
          render_terminals(terminals_on(:destination_terminal_id))
        end

        def commodities
          routed = TradeRoute.between_available_terminals.select(:commodity_id)

          @filters = Commodity.where(id: routed).includes(:build).sort_by(&:name).map do |commodity|
            Filter.new(category: "commodity", label: commodity.name, value: commodity.slug)
          end

          render "api/v1/shared/filters"
        end

        private def render_terminals(terminals)
          @filters = terminals.order(:name, :id).map do |terminal|
            Filter.new(category: terminal.star_system, label: terminal.name, value: terminal.id)
          end

          render "api/v1/shared/filters"
        end

        # Only terminals a route can actually be filtered down to.
        private def routed_terminals
          terminals_on(:origin_terminal_id).or(terminals_on(:destination_terminal_id))
        end

        private def terminals_on(column)
          Terminal.where(id: TradeRoute.between_available_terminals.select(column))
        end
      end
    end
  end
end
