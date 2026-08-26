# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventShipExpandInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            modelId: {type: :string, format: :uuid},
            positionIds: {type: :array, items: {type: :string, format: :uuid}}
          },
          required: %w[modelId]
        })
      end
    end
  end
end
