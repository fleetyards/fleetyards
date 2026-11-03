# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # When a mode that changes with the weapon's heat switches to this state.
      class EquipmentFireModeCondition
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            heatLevel: {type: :number},
            comparison: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
