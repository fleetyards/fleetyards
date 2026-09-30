# frozen_string_literal: true

module V1
  module Schemas
    module Models
      # The four damage types the penetration check weighs. Named like the full
      # armor component so a client can read either through the same code.
      class ModelDefenseArmor
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            health: {type: :number},
            damagePhysical: {type: :number},
            damageEnergy: {type: :number},
            damageDistortion: {type: :number},
            damageThermal: {type: :number},
            deflectionPhysical: {type: :number},
            deflectionEnergy: {type: :number},
            deflectionDistortion: {type: :number},
            deflectionThermal: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
