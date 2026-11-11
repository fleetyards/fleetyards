# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronShipSelectionInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            shipsFilter: ::V1::Schemas::Enums::FleetSquadronShipsFilterEnum,
            hangarGroupId: {type: [:string, :null], format: :uuid},
            vehicleIds: {type: :array, items: {type: :string, format: :uuid}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
