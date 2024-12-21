# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class HabitationCount
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            count: {type: :integer},
            type: {type: :string},
            typeLabel: {type: :string}
          },
          additionalProperties: false,
          required: %w[count type typeLabel]
        })
      end
    end
  end
end
