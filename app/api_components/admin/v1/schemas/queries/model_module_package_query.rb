# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelModulePackageQuery
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              idEq: {type: :string, format: :uuid},
              nameCont: {type: :string},
              nameEq: {type: :string},
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
