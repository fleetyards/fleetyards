# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class StandardMessage
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            code: {type: :string},
            message: {type: :string}
          },
          additionalProperties: false,
          required: %w[code message]
        })
      end
    end
  end
end
