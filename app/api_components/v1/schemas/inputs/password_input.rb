# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class PasswordInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            password: {type: :string},
            passwordConfirmation: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
