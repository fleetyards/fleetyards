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
            totalPages: {type: :integer}
          },
          required: %w[currentPage totalPages]
        })
      end
    end
  end
end
