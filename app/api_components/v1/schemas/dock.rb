# frozen_string_literal: true

module V1
  module Schemas
    class Dock
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          group: {type: :string},
          name: {type: :string},
          size: {type: :string},
          sizeLabel: {type: :string},
          type: {type: :string},
          typeLabel: {type: :string}
        },
        required: %w[name group size sizeLabel type typeLabel]
      })
    end
  end
end
