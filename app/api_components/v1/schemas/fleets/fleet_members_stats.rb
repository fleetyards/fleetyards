# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMembersStats
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            total: {type: :integer},
            metrics: {
              type: :object,
              properties: {
                totalAdmins: {type: :integer},
                totalOfficers: {type: :integer},
                totalMembers: {type: :integer}
              },
              additionalProperties: false,
              required: %w[totalAdmins totalOfficers totalMembers]
            }
          },
          additionalProperties: false,
          required: %w[total metrics]
        })
      end
    end
  end
end
