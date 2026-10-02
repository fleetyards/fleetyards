# frozen_string_literal: true

module V1
  module Schemas
    # A UEX trade terminal at a place.
    class LocationTerminal
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string}
        },
        additionalProperties: false,
        required: %w[id name]
      })
    end
  end
end
