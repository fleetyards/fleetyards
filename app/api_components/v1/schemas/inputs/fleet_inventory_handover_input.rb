# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # Part of one lot changing hands inside a fleet inventory. A null holder
      # on either side is the unassigned share. The lot is picked the way the
      # stock list tells lots apart: its grade, and for a crafted part the
      # recipe and the grades it was made from.
      class FleetInventoryHandoverInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            quantity: {type: :number, exclusiveMinimum: 0},
            fromHolderId: {type: [:string, :null], format: :uuid},
            toHolderId: {type: [:string, :null], format: :uuid},
            quality: {type: [:integer, :null], minimum: 0, maximum: 1000},
            craftedBlueprintId: {type: [:string, :null], format: :uuid},
            craftedQualities: {
              type: [:object, :null],
              additionalProperties: {type: :integer, minimum: 0, maximum: 1000}
            }
          },
          required: %w[quantity],
          additionalProperties: false
        })
      end
    end
  end
end
