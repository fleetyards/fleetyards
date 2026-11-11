# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanSlotCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            label: {type: :string},
            description: {type: [:string, :null]},
            filters: ::V1::Schemas::Hangar::Plans::HangarPlanSlotFilters
          },
          required: %w[label],
          additionalProperties: false
        })
      end
    end
  end
end
