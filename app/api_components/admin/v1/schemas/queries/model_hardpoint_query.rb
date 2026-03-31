# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelHardpointQuery
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              modelIdEq: {type: :string, format: :uuid},
              groupEq: {type: :string},
              hardpointTypeEq: {type: :string},
              sourceEq: {type: :string},
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
