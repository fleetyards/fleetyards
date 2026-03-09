# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class OauthApplicationQuery
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              ownerIdEq: {type: :string, format: :uuid}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
