# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # The admins, and while there is at most one, who a single promotion
      # would make the next.
      class FleetMemberHealthAdmins
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            totalCount: {type: :integer},
            items: {type: :array, items: ::V1::Schemas::Fleets::FleetMemberHealthMember},
            candidates: {type: :array, items: ::V1::Schemas::Fleets::FleetMemberHealthMember}
          },
          required: %w[totalCount items candidates],
          additionalProperties: false
        })
      end
    end
  end
end
