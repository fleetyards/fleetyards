# frozen_string_literal: true

module V1
  module Schemas
    # A jump point and where it leads. The destination is always named; it has
    # an id only when that system is listed too.
    class LocationJumpPoint
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          location: ::Shared::V1::Schemas::LocationLink,
          systemId: {type: :string, format: :uuid},
          destinationName: {type: :string},
          destinationSystemId: {type: [:string, :null], format: :uuid}
        },
        additionalProperties: false,
        required: %w[location systemId destinationName destinationSystemId]
      })
    end
  end
end
