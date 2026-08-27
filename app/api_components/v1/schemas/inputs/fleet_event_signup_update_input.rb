# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSignupUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            status: ::V1::Schemas::Enums::FleetEventSignupStatusEnum,
            vehicleId: {type: [:string, :null], format: :uuid},
            notes: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
