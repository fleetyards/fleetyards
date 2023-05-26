# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class StandardError
        include SchemaConcern

        schema :base, {
          type: :object,
          properties: {
            code: {type: :string},
            message: {type: :string}
          },
          required: %w[code message]
        }
      end
    end
  end
end
