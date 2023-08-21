# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Habitation
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            habitationName: {type: :string, nullable: true},
            type: {"$ref": "#/components/schemas/HabitationTypeEnum"},
            typeLabel: {type: :string}
          },
          additionalProperties: false,
          required: %w[name type typeLabel]
        })
      end
    end
  end
end
