# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentPenetration
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxThickness: {type: :number},
            nearRadius: {type: :number},
            farRadius: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
