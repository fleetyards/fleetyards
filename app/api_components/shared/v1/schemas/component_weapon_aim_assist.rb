# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentWeaponAimAssist
        include OpenapiRuby::Components::Base

        # Degrees the game bends a shot towards the target, and the wider cone
        # it uses between the two close-range distances (meters).
        schema({
          type: :object,
          properties: {
            nudgeAngle: {type: :number},
            innerAngle: {type: :number},
            outerAngle: {type: :number},
            closeRangeMin: {type: :number},
            closeRangeMax: {type: :number},
            closeInnerAngle: {type: :number},
            closeOuterAngle: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
