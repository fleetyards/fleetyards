# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanVehicleResource
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: [:string, :null]},
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              usedBy: ::V1::Schemas::Enums::NullableHangarPlanVehicleUseEnum,
              meltable: {type: [:boolean, :null], description: "Whether RSI lets the ship's pledge be melted; null until the hangar sync has read it"},
              meltValue: {type: [:number, :null], description: "The store credit melting the ship's pledge gives, as RSI lists it"},
              pledgeItemCount: {type: [:integer, :null], description: "How many items the pledge holds; melting the ship melts them all"}
            },
            additionalProperties: false,
            required: %w[id model]
          })
        end
      end
    end
  end
end
