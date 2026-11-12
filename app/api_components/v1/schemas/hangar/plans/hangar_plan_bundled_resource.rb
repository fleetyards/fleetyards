# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Plans
        class HangarPlanBundledResource
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            description: "A ship a pledge the plan buys back brings along besides the one its route starts as",
            properties: {
              pledgeStartId: {type: :string, format: :uuid, description: "The start that buys the pledge back"},
              pledgeName: {type: [:string, :null]},
              model: ::V1::Schemas::Hangar::Plans::HangarPlanModel,
              takenById: {type: [:string, :null], format: :uuid, description: "The bundled start that uses the ship; null while none does"}
            },
            additionalProperties: false,
            required: %w[pledgeStartId pledgeName model takenById]
          })
        end
      end
    end
  end
end
