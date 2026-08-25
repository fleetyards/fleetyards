# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMembershipCapabilities
        include OpenapiRuby::Components::Base

        PROPERTIES = ::FleetMembership::CAPABILITY_PRIVILEGES.keys.map do |capability|
          capability.to_s.camelize(:lower)
        end.freeze

        schema({
          type: :object,
          properties: PROPERTIES.index_with { {type: :boolean} },
          additionalProperties: false,
          required: PROPERTIES
        })
      end
    end
  end
end
