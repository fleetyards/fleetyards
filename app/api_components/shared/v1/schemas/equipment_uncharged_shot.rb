# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # What a charged mode deals when released before it charges.
      class EquipmentUnchargedShot
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            alpha: {type: :number},
            dps: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
