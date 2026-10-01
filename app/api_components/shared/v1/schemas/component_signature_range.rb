# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentSignatureRange
        include OpenapiRuby::Components::Base

        # A signature at launch and at burn-out.
        schema({
          type: :object,
          properties: {
            start: {type: :number},
            end: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
