# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # One row of a flag's history. `actor` is null for the changes no person
      # made -- the deploy's sync, a console call, and the rows seeded from
      # flipper_gates -- which is what `source` is there to explain.
      class FeatureChange
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string},
            operation: {type: :string},
            gateName: {type: [:string, :null]},
            thing: {type: [:string, :null]},
            stateAfter: {type: :string},
            source: {type: :string},
            actor: {type: [:string, :null]},
            createdAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id operation gateName thing stateAfter source actor createdAt]
        })
      end
    end
  end
end
