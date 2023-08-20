# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class SearchQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            search: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
