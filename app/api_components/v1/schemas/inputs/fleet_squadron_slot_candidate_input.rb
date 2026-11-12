# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronSlotCandidateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            username: {type: :string},
            vehicleId: {type: [:string, :null], format: :uuid}
          },
          additionalProperties: false,
          required: %w[username]
        })
      end
    end
  end
end
