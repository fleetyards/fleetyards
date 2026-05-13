# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class SortInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            sorting: {
              type: :array,
              items: {type: :string, format: :uuid}
            }
          },
          required: %w[sorting],
          additionalProperties: false
        })
      end
    end
  end
end
