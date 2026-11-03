# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentModifierRecoil
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            yaw: {type: :number},
            pitch: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
