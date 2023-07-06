# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleCreateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            modelId: {type: :string, format: :uuid},
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
          required: %w[modelId]
        })
      end
    end
  end
end
