# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class CartStrategyEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::Carts::TripPlan::STRATEGIES,
          "x-enumNames": ::Carts::TripPlan::STRATEGIES.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
