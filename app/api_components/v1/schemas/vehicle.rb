# frozen_string_literal: true

module V1
  module Schemas
    class Vehicle
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string, nullable: true},
          slug: {type: :string, nullable: true},
          serial: {type: :string, nullable: true},
          wanted: {type: :boolean},
          boughtVia: {type: :string, enum: %w[pledge store]},
          boughtViaLabel: {type: :string},
          loaner: {type: :boolean},
          flagship: {type: :boolean},
          public: {type: :boolean},
          nameVisible: {type: :boolean},
          saleNotify: {type: :boolean},
          alternativeNames: {type: :array, items: {type: :string}},
          model: {"$ref": "#/components/schemas/Model"},
          paint: {"$ref": "#/components/schemas/Paint"},
          upgrade: {"$ref": "#/components/schemas/Upgrade"},
          hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}},
          hangarGroups: {type: :array, items: {"$ref": "#/components/schemas/HangarGroup"}},
          modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
          modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
          modulePackage: {"$ref": "#/components/schemas/ModulePackage"}
        },
        required: %w[id model]
      })

      schema :minimal,
        {
          properties: {
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[createdAt updatedAt]
        },
        extends: :base
    end
  end
end
