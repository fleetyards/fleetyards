# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class OauthApplicationQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              ownerIdEq: {type: :string, format: :uuid}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
