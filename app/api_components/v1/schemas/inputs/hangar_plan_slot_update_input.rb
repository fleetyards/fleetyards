# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarPlanSlotUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            label: {type: :string},
            description: {type: [:string, :null]},
            filters: ::V1::Schemas::Hangar::Plans::HangarPlanSlotFilters,
            quantity: {type: :integer, minimum: 1}
          },
          additionalProperties: false
        })
      end
    end
  end
end
