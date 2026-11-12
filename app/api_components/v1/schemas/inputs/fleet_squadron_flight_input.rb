# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronFlightInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            description: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
