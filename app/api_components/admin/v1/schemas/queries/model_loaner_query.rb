# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelLoanerQuery
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              modelIdEq: {type: :string, format: :uuid},
              loanerModelIdEq: {type: :string, format: :uuid},
              hiddenEq: {type: :boolean}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
