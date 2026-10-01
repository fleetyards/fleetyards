# frozen_string_literal: true

module V1
  module Schemas
    module Models
      class ModelDefenseShield
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxHealth: {type: :number},
            maxRegen: {type: :number},
            damagedRegenDelay: {type: :number},
            absorption: ::Shared::V1::Schemas::ComponentDamageTypeMap,
            resistance: ::Shared::V1::Schemas::ComponentDamageTypeMap
          },
          additionalProperties: false,
          required: %w[maxHealth maxRegen]
        })
      end
    end
  end
end
