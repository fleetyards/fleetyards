# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ConfirmAccessCodeInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            token: {type: :string},
            confirmationCode: {type: :string}
          },
          additionalProperties: false,
          required: %w[token confirmationCode]
        })
      end
    end
  end
end
