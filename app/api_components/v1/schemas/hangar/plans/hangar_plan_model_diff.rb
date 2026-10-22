# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanModelDiff
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "How many of a model each side has; for the live comparison the left side is the hangar",
            properties: {
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              leftCount: {type: :integer},
              rightCount: {type: :integer},
              change: ::V1::Schemas::Enums::HangarPlanModelChangeEnum
            },
            additionalProperties: false,
            required: %w[model leftCount rightCount change]
          })
        end
      end
    end
  end
end
