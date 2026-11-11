# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadronShipRequestVehicle
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: [:string, :null]},
              model: ::V1::Schemas::Fleets::Events::FleetEventSignupVehicleModel
            },
            additionalProperties: false,
            required: %w[id name model]
          })
        end
      end
    end
  end
end
