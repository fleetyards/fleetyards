# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleUpdateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            name: {type: :string, nullable: true},
            serial: {type: :string, nullable: true},
            wanted: {type: :boolean},
            nameVisible: {type: :boolean},
            public: {type: :boolean},
            saleNotify: {type: :boolean},
            flagship: {type: :boolean},
            modelPaintId: {type: :string, format: :uuid, nullable: true},
            boughtVia: {"$ref": "#/components/schemas/BoughtViaEnum"},
            hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
            alternativeNames: {type: :array, items: {type: :string}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
