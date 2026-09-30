# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentSensitivityModifiers
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            sensitivityAddition: {type: :number},
            # The contact group the offset applies to, as the game names it.
            contactGroup: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
