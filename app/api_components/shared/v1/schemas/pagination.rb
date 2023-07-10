# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Pagination
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            currentPage: {type: :integer},
            totalPages: {type: :integer},
            defaultPerPage: {type: :integer},
            maxPerPage: {type: :integer},
            perPageSteps: {
              type: :array,
              items: {
                oneOf: [
                  {type: :string},
                  {type: :integer}
                ]
              }
            }
          },
          additionalProperties: false,
          required: %w[currentPage totalPages defaultPerPage maxPerPage]
        })
      end
    end
  end
end
