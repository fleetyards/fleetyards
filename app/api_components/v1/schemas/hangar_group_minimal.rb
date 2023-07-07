# frozen_string_literal: true

module V1
  module Schemas
    class HangarGroupMinimal < HangarGroup
      include SchemaConcern

      schema({
        properties: {
          public: {type: :boolean},
          sort: {type: :integer, nullable: true},
          vehiclesCount: {type: :integer},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[public vehiclesCount createdAt updatedAt]
      })
    end
  end
end
