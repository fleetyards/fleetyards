# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One range per damage type, used for both shield resistance and
      # absorption.
      class ComponentDamageTypeMap
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            physical: ComponentDamageRange,
            energy: ComponentDamageRange,
            distortion: ComponentDamageRange,
            thermal: ComponentDamageRange,
            biochemical: ComponentDamageRange,
            stun: ComponentDamageRange
          },
          additionalProperties: false
        })
      end
    end
  end
end
