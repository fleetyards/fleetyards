# frozen_string_literal: true

module V1
  module Schemas
    class HangarGroupMinimalPublic < HangarGroupPublic
      include SchemaConcern

      schema({
        properties: {
          sort: {type: :integer, nullable: true},
          vehiclesCount: {type: :integer},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[vehiclesCount createdAt updatedAt]
      })
    end
  end
end
