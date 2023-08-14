# frozen_string_literal: true

module V1
  module Schemas
    class FleetCheck
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          taken: {type: :boolean}
        },
        additionalProperties: false,
        required: %i[taken]
      })
    end
  end
end
