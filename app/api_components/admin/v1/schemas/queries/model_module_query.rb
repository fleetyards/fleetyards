# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelModuleQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameIn: {type: :string},
              idEq: {type: :string, format: :uuid},
              nameCont: {type: :string},
              nameEq: {type: :string},
              moduleHardpointsModelIdEq: {type: :string, format: :uuid},
              moduleHardpointsModelIdNotEq: {type: :string, format: :uuid}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
