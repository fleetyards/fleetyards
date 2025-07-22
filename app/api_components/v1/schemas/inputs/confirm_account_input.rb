# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ConfirmAccountInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            token: {type: :string}
          },
          additionalProperties: false,
          required: %w[token]
        })
      end
    end
  end
end
