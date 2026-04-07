# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleCreateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            modelId: {type: :string, format: :uuid},
            name: {type: :string, nullable: true},
            serial: {type: :string, nullable: true},
            wanted: {type: :boolean},
            nameVisible: {type: :boolean},
            public: {type: :boolean},
            saleNotify: {type: :boolean},
            flagship: {type: :boolean},
            modelPaintId: {type: :string, format: :uuid, nullable: true},
            boughtVia: {"$ref": "#/components/schemas/BoughtViaEnum"},
            hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}, nullable: true},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}, nullable: true},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}, nullable: true},
            alternativeNames: {type: :array, items: {type: :string}, nullable: true}
          },
          additionalProperties: false,
          required: %w[modelId]
        })
      end
    end
  end
end
