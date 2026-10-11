# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # The first few members of one check, with how many there are in all.
      class FleetMemberHealthSection
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            totalCount: {type: :integer},
            items: {type: :array, items: ::V1::Schemas::Fleets::FleetMember}
          },
          required: %w[totalCount items],
          additionalProperties: false
        })
      end
    end
  end
end
