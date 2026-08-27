# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentDamageRange
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            min: {type: :number},
            max: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
