# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelSnubCraftQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              modelIdEq: {type: :string, format: :uuid},
              snubCraftIdEq: {type: :string, format: :uuid}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
