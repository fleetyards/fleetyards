# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetInventoryItemUpdateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            notes: {type: :string, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
