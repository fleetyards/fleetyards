# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # A role nobody holds, and the members a single promotion would move into
      # it: those holding the rank right below.
      class FleetMemberHealthEmptyRole
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            role: ::V1::Schemas::Fleets::FleetRole,
            candidates: {type: :array, items: ::V1::Schemas::Fleets::FleetMemberHealthMember}
          },
          required: %w[role candidates],
          additionalProperties: false
        })
      end
    end
  end
end
