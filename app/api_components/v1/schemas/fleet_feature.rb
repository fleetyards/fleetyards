# frozen_string_literal: true

module V1
  module Schemas
    class FleetFeature
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          enabled: {type: :boolean},
          toggleable: {type: :boolean},
          groups: {
            type: :array,
            items: {type: :string}
          }
        },
        additionalProperties: false,
        required: %w[name enabled toggleable groups]
      })
    end
  end
end
