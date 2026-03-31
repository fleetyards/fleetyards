# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Pagination
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            totalCount: {type: :integer},
            currentPage: {type: :integer},
            totalPages: {type: :integer},
            perPage: {type: :integer},
            defaultPerPage: {type: :integer},
            maxPerPage: {type: :integer},
            perPageSteps: {
              type: :array,
              items: {
                anyOf: [
                  {type: :string},
                  {type: :integer}
                ]
              }
            }
          },
          additionalProperties: false,
          required: %w[currentPage totalPages totalCount perPage]
        })
      end
    end
  end
end
