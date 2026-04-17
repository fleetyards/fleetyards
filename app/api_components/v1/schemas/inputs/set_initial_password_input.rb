# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class SetInitialPasswordInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            password: {type: :string},
            passwordConfirmation: {type: :string}
          },
          additionalProperties: false,
          required: %w[password passwordConfirmation]
        })
      end
    end
  end
end
