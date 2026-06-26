# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class DestroyedFleetQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameOrFidCont: {type: :string}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
