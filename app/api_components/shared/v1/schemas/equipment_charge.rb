# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # How a charged mode charges, and what full charge multiplies.
      class EquipmentCharge
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            time: {type: :number},
            overchargeTime: {type: :number},
            overchargedTime: {type: :number},
            cooldown: {type: :number},
            damageMultiplier: {type: :number},
            projectileSpeedMultiplier: {type: :number},
            partial: {type: :boolean, description: "Whether a part charge scales the shot part of the way"},
            uncharged: ::Shared::V1::Schemas::EquipmentUnchargedShot
          },
          additionalProperties: false
        })
      end
    end
  end
end
