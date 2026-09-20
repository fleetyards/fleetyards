# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class DockAdditionQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              dockIdEq: {type: :string, format: :uuid},
              modelIdEq: {type: :string, format: :uuid}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
