# frozen_string_literal: true

module V1
  module Schemas
    class ConfirmAccessEmailResponse
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          code: {type: :string},
          message: {type: :string},
          token: {type: :string}
        },
        additionalProperties: false,
        required: %w[code message token]
      })
    end
  end
end
