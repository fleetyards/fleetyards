# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class HangarInventoryQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            s: {type: :string},
            sorts: {type: :string}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
