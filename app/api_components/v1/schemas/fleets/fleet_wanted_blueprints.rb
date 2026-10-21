# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetWantedBlueprints < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/FleetWantedBlueprint"}}
          },
          required: %w[items]
        })
      end
    end
  end
end
