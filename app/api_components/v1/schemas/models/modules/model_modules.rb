# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Modules
        class ModelModules < Shared::V1::Schemas::BaseList
          include OpenapiRuby::Components::Base

          schema({
            properties: {
              items: {type: :array, items: {"$ref": "#/components/schemas/ModelModule"}},
              craftableComponentIds: {
                type: :array,
                items: {type: :string, format: :uuid},
                description: "The parts in these modules' ports a recipe makes, for a loadout to offer crafting on"
              }
            },
            required: %w[items]
          })
        end
      end
    end
  end
end
