# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # What stops a run from loading more: the ship's hold, stock at the buy
      # terminal, demand at the sell terminal, or the budget.
      class NullableTradeRouteLoadLimitEnum
        include OpenapiRuby::Components::Base

        VALUES = ::TradeRoute::LOAD_LIMITS

        schema({
          type: [:string, :null],
          enum: [*VALUES, nil],
          "x-enumNames": [*VALUES.map { |value| transform_enum_key(value) }, "NULL"]
        })
      end
    end
  end
end
