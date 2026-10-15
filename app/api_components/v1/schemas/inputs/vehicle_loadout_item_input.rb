# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLoadoutItemInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slot: {type: :string},
            modelModuleId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[slot modelModuleId]
        })
      end
    end
  end
end
