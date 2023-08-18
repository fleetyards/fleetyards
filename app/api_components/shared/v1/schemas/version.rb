# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Version
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            version: {type: :string},
            codename: {type: :string}
          },
          additionalProperties: false,
          required: %i[version codename]
        })
      end
    end
  end
end
