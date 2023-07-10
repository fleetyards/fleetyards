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
            wanted: {type: :boolean, nullable: true},
            nameVisible: {type: :boolean, nullable: true},
            public: {type: :boolean, nullable: true},
            saleNotify: {type: :boolean, nullable: true},
            flagship: {type: :boolean, nullable: true},
            modelPaintId: {type: :string, format: :uuid, nullable: true},
            boughtVia: {"$ref": "#/components/schemas/BoughtViaEnum", nullable: true},
            hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}, nullable: true},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}, nullable: true},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}, nullable: true},
            alternativeNames: {type: :array, items: {type: :string}, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
