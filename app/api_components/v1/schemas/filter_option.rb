# frozen_string_literal: true

module V1
  module Schemas
    class FilterOption
      include SchemaConcern

      schema :base, {
        type: :object,
        properties: {
          name: {type: :string},
          value: {type: :string},
          category: {type: :string},
          icon: {type: :string, nullable: true}
        },
        required: %w[name value category]
      }
    end
  end
end
