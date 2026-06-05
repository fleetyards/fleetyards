# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class OauthApplicationUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: [:string, :null]},
            redirectUri: {type: [:string, :null]},
            confidential: {type: :boolean},
            scopes: {type: [:array, :null], items: {type: :string}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
