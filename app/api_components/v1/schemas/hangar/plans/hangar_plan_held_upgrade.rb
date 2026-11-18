# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanHeldUpgrade
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "A planned upgrade still to buy that an update takes from the hangar instead",
            properties: {
              stepId: {type: :string, format: :uuid},
              fromModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              toModel: ::V1::Schemas::Hangar::Plans::HangarPlanModel
            },
            additionalProperties: false,
            required: %w[stepId fromModel toModel]
          })
        end
      end
    end
  end
end
