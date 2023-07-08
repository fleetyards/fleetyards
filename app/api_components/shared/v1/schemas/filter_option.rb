# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class FilterOption
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            category: {type: :string},
            icon: {type: :string, nullable: true},
            name: {type: :string},
            value: {type: :string}
          },
          required: %w[name value category]
        })
      end
    end
  end
end
