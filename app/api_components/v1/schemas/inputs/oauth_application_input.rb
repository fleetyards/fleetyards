# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class OauthApplicationInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            redirectUri: {type: :string},
            confidential: {type: :boolean},
            scopes: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          required: %w[name redirectUri]
        })
      end
    end
  end
end
