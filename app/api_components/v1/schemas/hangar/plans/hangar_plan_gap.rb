# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanGap
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              slotId: {type: :string, format: :uuid},
              label: {type: :string},
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel
            },
            additionalProperties: false,
            required: %w[slotId label model]
          })
        end
      end
    end
  end
end
