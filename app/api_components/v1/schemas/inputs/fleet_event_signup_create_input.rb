# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventSignupCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            status: {
              type: :string,
              enum: V1::Schemas::Fleets::Events::FleetEventSignup::STATUSES
            },
            vehicleId: {type: :string, format: :uuid},
            notes: {type: :string},
            occurrenceDate: {type: :string, format: :date}
          },
          additionalProperties: false
        })
      end
    end
  end
end
