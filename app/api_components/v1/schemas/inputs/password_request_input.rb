# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class PasswordRequestInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            email: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
