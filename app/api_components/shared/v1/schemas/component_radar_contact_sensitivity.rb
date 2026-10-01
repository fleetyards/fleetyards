# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentRadarContactSensitivity
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            sensitivityAddition: {type: :number},
            # The contact groups the offset applies to, as the game names
            # them; an unnamed group is left as its reference.
            contactGroups: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          required: %w[sensitivityAddition contactGroups]
        })
      end
    end
  end
end
