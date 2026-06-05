# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            modelId: {type: :string, format: :uuid},
            name: {type: [:string, :null]},
            serial: {type: [:string, :null]},
            wanted: {type: :boolean},
            nameVisible: {type: :boolean},
            public: {type: :boolean},
            saleNotify: {type: :boolean},
            flagship: {type: :boolean},
            modelPaintId: {type: [:string, :null], format: :uuid},
            boughtVia: {"$ref": "#/components/schemas/BoughtViaEnum"},
            hangarGroupIds: {type: [:array, :null], items: {type: :string, format: :uuid}},
            modelModuleIds: {type: [:array, :null], items: {type: :string, format: :uuid}},
            modelUpgradeIds: {type: [:array, :null], items: {type: :string, format: :uuid}},
            alternativeNames: {type: [:array, :null], items: {type: :string}}
          },
          additionalProperties: false,
          required: %w[modelId]
        })
      end
    end
  end
end
