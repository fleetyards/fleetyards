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
              usedBy: ::V1::Schemas::Enums::NullableHangarPlanVehicleUseEnum
            },
            additionalProperties: false,
            required: %w[id model]
          })
        end
      end
    end
  end
end
