# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class DockQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              parentIdEq: {type: :string, format: :uuid},
              parentTypeEq: {type: :string},
              dockTypeEq: {type: :string},
              shipSizeEq: {type: :string},
              nameCont: {type: :string}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
