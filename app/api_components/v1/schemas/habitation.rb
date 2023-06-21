# frozen_string_literal: true

module V1
  module Schemas
    class Habitation
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          habitationName: {type: :string},
          type: {type: :string},
          typeLabel: {type: :string}
        },
        required: %w[name habitationName type typeLabel]
      })
    end
  end
end
