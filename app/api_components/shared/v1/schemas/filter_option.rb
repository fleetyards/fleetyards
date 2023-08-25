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
            icon: {type: :string},
            name: {type: :string, deprecated: true},
            label: {type: :string},
            value: {type: :string}
          },
          additionalProperties: false,
          required: %w[name value category]
        })
      end
    end
  end
end
