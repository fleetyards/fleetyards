# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMembersMetrics
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            membersByRole: {
              type: :object,
              additionalProperties: {type: :integer}
            }
          },
          additionalProperties: false,
          required: %w[membersByRole]
        })
      end
    end
  end
end
