# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetMembershipUpdateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            primary: {type: :boolean},
            shipsFilter: {"$ref": "#/components/schemas/FleetMembershipShipsFilterEnum"},
            hangarGroupId: {type: :string, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
