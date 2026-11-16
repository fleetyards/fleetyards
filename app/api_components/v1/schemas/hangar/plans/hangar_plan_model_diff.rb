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
              change: ::V1::Schemas::Enums::HangarPlanModelChangeEnum,
              inCount: {type: :integer, description: "Ships of the model that come in, counted one by one rather than net"},
              outCount: {type: :integer, description: "Ships of the model that go, counted one by one rather than net"}
            },
            additionalProperties: false,
            required: %w[model leftCount rightCount change inCount outCount]
          })
        end
      end
    end
  end
end
