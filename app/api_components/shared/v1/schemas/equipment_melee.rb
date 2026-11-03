# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentMelee
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            attacks: {type: :array, items: ::Shared::V1::Schemas::EquipmentMeleeAttack}
          },
          additionalProperties: false
        })
      end
    end
  end
end
