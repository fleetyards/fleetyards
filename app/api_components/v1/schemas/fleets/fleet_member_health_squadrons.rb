# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMemberHealthSquadrons
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            totalCount: {type: :integer},
            items: {type: :array, items: ::V1::Schemas::Fleets::FleetMemberHealthSquadron}
          },
          required: %w[totalCount items],
          additionalProperties: false
        })
      end
    end
  end
end
