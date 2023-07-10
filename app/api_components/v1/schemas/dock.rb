# frozen_string_literal: true

module V1
  module Schemas
    class Dock
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          group: {type: :string, nullable: true},
          size: {type: :string},
          sizeLabel: {type: :string},
          type: {type: :string},
          typeLabel: {type: :string}
        },
        additionalProperties: false,
        required: %w[name size sizeLabel type typeLabel]
      })
    end
  end
end
