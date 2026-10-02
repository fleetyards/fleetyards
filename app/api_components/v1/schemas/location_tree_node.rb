# frozen_string_literal: true

module V1
  module Schemas
    # One body of a system, its moons and cities beneath it in orbit order, and
    # everything else under it counted by kind.
    class LocationTreeNode
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          location: ::V1::Schemas::LocationTreeBody,
          counts: {type: :array, items: ::V1::Schemas::LocationKindCount},
          # A planet's Lagrange points, which the game draws under the star.
          lagrangePoints: {type: :array, items: ::Shared::V1::Schemas::LocationLink},
          # A star's jump gateways.
          gateways: {type: :array, items: ::Shared::V1::Schemas::LocationLink},
          children: {type: :array, items: {"$ref": "#/components/schemas/LocationTreeNode"}}
        },
        additionalProperties: false,
        required: %w[location counts lagrangePoints gateways children]
      })
    end
  end
end
