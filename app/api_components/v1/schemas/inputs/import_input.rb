# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ImportInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            import: {type: :string}
          },
          additionalProperties: false,
          required: %w[import]
        })
      end
    end
  end
end
