# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSlotSortInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slottableType: {type: :string, enum: %w[FleetEventTeam FleetEventShip]},
            slottableId: {type: :string, format: :uuid},
            sorting: {type: :array, items: {type: :string, format: :uuid}}
          },
          required: %w[slottableType slottableId sorting]
        })
      end
    end
  end
end
