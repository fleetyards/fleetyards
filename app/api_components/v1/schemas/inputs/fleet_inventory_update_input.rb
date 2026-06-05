# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetInventoryUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            description: {type: [:string, :null]},
            managedBy: {type: [:string, :null], format: :uuid},
            visibility: {type: :string, enum: %w[members_only officers_only]},
            location: {type: [:string, :null]},
            image: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
