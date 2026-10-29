# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanKeepCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            vehicleIds: {type: :array, items: {type: :string, format: :uuid}, minItems: 1, description: "Hangar ships to keep as they are"}
          },
          required: %w[vehicleIds],
          additionalProperties: false
        })
      end
    end
  end
end
