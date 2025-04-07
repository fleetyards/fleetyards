# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Inputs
        class CheckInput
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              value: {type: :string}
            },
            additionalProperties: false,
            required: %w[value]
          })
        end
      end
    end
  end
end
