# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanFleetEntry
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "One ship of the hangar once the plan is carried out: a unit of a slot, or a hangar ship the plan leaves alone",
            properties: {
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              slotId: {type: [:string, :null], format: :uuid},
              slotLabel: {type: [:string, :null]},
              vehicleId: {type: [:string, :null], format: :uuid, description: "The hangar ship that is or becomes this ship"},
              vehicleName: {type: [:string, :null]},
              vehicleStatus: ::V1::Schemas::Enums::HangarPlanVehicleStatusEnum
            },
            additionalProperties: false,
            required: %w[model]
          })
        end
      end
    end
  end
end
