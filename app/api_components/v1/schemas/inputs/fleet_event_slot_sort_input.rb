# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSlotSortInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slottableType: ::V1::Schemas::Enums::FleetEventSlottableTypeEnum,
            slottableId: {type: :string, format: :uuid},
            sorting: {type: :array, items: {type: :string, format: :uuid}}
          },
          required: %w[slottableType slottableId sorting]
        })
      end
    end
  end
end
