# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentPingProperties
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            cooldownTime: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
