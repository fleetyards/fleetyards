# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ScDataVersion
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            version: {type: :string}
          },
          additionalProperties: false,
          required: %i[version]
        })
      end
    end
  end
end
