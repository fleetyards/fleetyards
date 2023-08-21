# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class DockCount
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            count: {type: :integer},
            size: {type: :string},
            type: {type: :string},
            typeLabel: {type: :string}
          },
          additionalProperties: false,
          required: %w[size count type typeLabel]
        })
      end
    end
  end
end
