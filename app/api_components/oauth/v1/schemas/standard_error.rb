# frozen_string_literal: true

module Oauth
  module V1
    module Schemas
      class StandardError
        include OpenapiRuby::Components::Base

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
