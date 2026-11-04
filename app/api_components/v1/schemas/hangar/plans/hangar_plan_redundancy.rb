# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanRedundancy
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "Ships of the planned hangar that do the same job: one model more than once, or several models of one role",
            properties: {
              kind: ::V1::Schemas::Enums::HangarPlanRedundancyKindEnum,
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              classificationLabel: {type: [:string, :null]},
              sizeLabel: {type: [:string, :null]},
              focusLabel: {type: [:string, :null]},
              entries: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanFleetEntry}
            },
            additionalProperties: false,
            required: %w[kind entries]
          })
        end
      end
    end
  end
end
