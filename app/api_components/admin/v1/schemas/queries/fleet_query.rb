# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class FleetQuery
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              fidCont: {type: :string}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
