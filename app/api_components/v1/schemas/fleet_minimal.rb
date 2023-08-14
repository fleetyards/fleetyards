# frozen_string_literal: true

module V1
  module Schemas
    class FleetMinimal < FleetBase
      include SchemaConcern

      schema({
        properties: {
          myFleet: {type: :boolean},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[myFleet createdAt updatedAt]
      })
    end
  end
end
