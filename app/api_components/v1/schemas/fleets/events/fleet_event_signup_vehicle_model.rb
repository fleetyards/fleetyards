# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Events
        class FleetEventSignupVehicleModel
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              classification: {type: :string},
              focus: {type: :string},
              size: {type: :string},
              crew: {type: [:integer, :null]},
              cargo: {type: :integer},
              positionCount: {type: :integer}
            }
          })
        end
      end
    end
  end
end
