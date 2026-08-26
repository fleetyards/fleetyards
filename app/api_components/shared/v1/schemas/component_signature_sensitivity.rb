# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentSignatureSensitivity
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            sensitivity: {type: :number},
            piercing: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
