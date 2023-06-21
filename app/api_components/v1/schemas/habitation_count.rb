# frozen_string_literal: true

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
        required: %w[count type typeLabel]
      })
    end
  end
end
