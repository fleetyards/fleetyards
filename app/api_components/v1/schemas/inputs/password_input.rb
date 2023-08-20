# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class PasswordInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            currentPassword: {type: :string},
            password: {type: :string},
            passwordConfirmation: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
