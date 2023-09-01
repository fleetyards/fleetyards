# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Check
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
end
