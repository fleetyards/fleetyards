# frozen_string_literal: true

module V1
  module Schemas
    class Galaxy
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          systems: {type: :array, items: ::V1::Schemas::StarSystem},
          tunnels: {type: :array, items: ::V1::Schemas::JumpTunnel}
        },
        additionalProperties: false,
        required: %w[systems tunnels]
      })
    end
  end
end
