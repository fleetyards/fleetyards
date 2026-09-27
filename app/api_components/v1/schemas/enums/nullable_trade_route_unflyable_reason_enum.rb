# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Which end of a run the chosen ship can't reach because it can't land on
      # a planet: the origin, the destination, or both. Null when it can fly
      # the run, or without a ship.
      class NullableTradeRouteUnflyableReasonEnum
        include OpenapiRuby::Components::Base

        VALUES = ::TradeRoute::UNFLYABLE_REASONS

        schema({
          type: [:string, :null],
          enum: [*VALUES, nil],
          "x-enumNames": [*VALUES.map { |value| transform_enum_key(value) }, "NULL"]
        })
      end
    end
  end
end
