# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanListItem
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              description: {type: [:string, :null]},
              basedOnAt: {type: :string, format: "date-time"},
              shared: {type: :boolean},
              slotsCount: {type: :integer},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name basedOnAt shared slotsCount createdAt updatedAt]
          })
        end
      end
    end
  end
end
