# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # Nullable rather than optional: clearing a nomination is an ordinary
      # thing to want, and an absent key could not express it.
      class SupporterNominationInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fleetId: {type: [:string, :null], format: :uuid}
          },
          required: %w[fleetId],
          additionalProperties: false
        })
      end
    end
  end
end
