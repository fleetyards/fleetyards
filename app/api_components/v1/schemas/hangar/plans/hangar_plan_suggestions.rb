# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanSuggestions
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              redundancies: {type: :array, items: ::V1::Schemas::Hangar::Plans::HangarPlanRedundancy}
            },
            additionalProperties: false,
            required: %w[redundancies]
          })
        end
      end
    end
  end
end
