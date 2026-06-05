# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class DockInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: [:string, :null]},
              dockType: {type: :string},
              shipSize: {type: :string},
              group: {type: [:string, :null]},
              length: {type: [:number, :null]},
              beam: {type: [:number, :null]},
              height: {type: [:number, :null]},
              minShipSize: {type: [:integer, :null]},
              maxShipSize: {type: [:integer, :null]},
              modelId: {type: [:string, :null], format: :uuid}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
