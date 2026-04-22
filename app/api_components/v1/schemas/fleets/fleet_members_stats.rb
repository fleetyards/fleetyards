# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMembersStats
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            total: {type: :integer},
            metrics: {
              type: :object,
              properties: {
                membersByRole: {
                  type: :object,
                  additionalProperties: {type: :integer}
                }
              },
              additionalProperties: false,
              required: %w[membersByRole]
            }
          },
          additionalProperties: false,
          required: %w[total metrics]
        })
      end
    end
  end
end
