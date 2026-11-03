# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentMine
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            trigger: {type: :string},
            radius: {type: :number},
            warningRadius: {type: :number},
            horizontalAngle: {type: :number},
            verticalAngle: {type: :number},
            length: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
