# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One band of a component's power curve. Eight component types carried an
      # identical copy of this shape, which gave the generated client eight
      # unrelated types for the same two numbers.
      class ComponentPowerRangeEntry
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            start: {type: :number},
            modifier: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
