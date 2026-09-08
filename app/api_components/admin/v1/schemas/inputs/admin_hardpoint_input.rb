# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        # `source` is deliberately absent. A created slot is always
        # `ship_matrix`, and an update must not move one between owners: the
        # loader owns the game-files half and would rewrite it on the next load
        # anyway.
        class AdminHardpointInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              parentId: {type: :string, format: :uuid},
              parentType: {type: :string},
              scName: {type: :string},
              componentId: {type: [:string, :null], format: :uuid},
              group: ::Shared::V1::Schemas::Enums::HardpointGroupEnum,
              category: ::Shared::V1::Schemas::Enums::HardpointCategoryEnum,
              minSize: {type: [:integer, :null]},
              maxSize: {type: [:integer, :null]},
              details: {type: [:string, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
