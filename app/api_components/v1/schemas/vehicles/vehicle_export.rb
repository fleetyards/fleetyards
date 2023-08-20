# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleExport
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            slug: {type: :string},
            shipCode: {type: :string, nullable: true},
            manufacturerName: {type: :string},
            manufacturerCode: {type: :string, nullable: true},
            paintSlug: {type: :string, nullable: true},
            shipName: {type: :string, nullable: true},
            shipSerial: {type: :string, nullable: true},
            wanted: {type: :boolean},
            flagship: {type: :boolean},
            public: {type: :boolean},
            saleNotify: {type: :boolean},
            nameVisible: {type: :boolean},
            groups: {type: :array, items: {type: :string}},
            modules: {type: :array, items: {type: :string}},
            upgrades: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          required: %w[
            name slug manufacturerName wanted flagship public saleNotify
            nameVisible groups modules upgrades
          ]
        })
      end
    end
  end
end
