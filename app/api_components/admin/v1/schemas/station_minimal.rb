# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class StationMinimal < Station
        include SchemaConcern

        schema({
          properties: {
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[createdAt updatedAt]
        })
      end
    end
  end
end
