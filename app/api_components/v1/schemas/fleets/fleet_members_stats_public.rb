# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMembersStatsPublic
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            total: {type: :integer}
          },
          additionalProperties: false,
          required: %w[total]
        })
      end
    end
  end
end
