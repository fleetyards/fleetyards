# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class OauthApplicationUpdateInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              name: {type: :string, nullable: true},
              redirectUri: {type: :string, nullable: true},
              confidential: {type: :boolean},
              scopes: {type: :array, items: {type: :string}, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
