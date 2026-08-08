# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentArmor
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            health: {type: :number},
            damagePhysical: {type: :number},
            damageEnergy: {type: :number},
            damageDistortion: {type: :number},
            damageThermal: {type: :number},
            damageBiochemical: {type: :number},
            damageStun: {type: :number},
            deflectionPhysical: {type: :number},
            deflectionEnergy: {type: :number},
            deflectionDistortion: {type: :number},
            deflectionThermal: {type: :number},
            selfResistancePhysical: {type: :number},
            selfResistanceEnergy: {type: :number},
            selfResistanceDistortion: {type: :number},
            selfResistanceThermal: {type: :number},
            signalInfrared: {type: :number},
            signalElectromagnetic: {type: :number},
            signalCrossSection: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
