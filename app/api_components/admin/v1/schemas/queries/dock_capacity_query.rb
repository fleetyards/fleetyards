# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class DockCapacityQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              dockIdEq: {type: :string, format: :uuid},
              ladderEq: {type: :string},
              sizeEq: {type: :string}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
