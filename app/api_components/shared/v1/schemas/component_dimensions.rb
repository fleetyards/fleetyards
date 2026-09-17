# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The physical size of one item, in metres.
      class ComponentDimensions
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            x: {type: :number},
            y: {type: :number},
            z: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
