# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Fleetchart
        class FleetVehicleSquadron
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              color: {type: [:string, :null]}
            },
            required: %w[id name slug]
          })
        end
      end
    end
  end
end
