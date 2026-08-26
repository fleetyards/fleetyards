# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLoadoutHardpointInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            modelHardpointId: {type: :string, format: :uuid},
            componentId: {type: [:string, :null], format: :uuid},
            _destroy: {type: :boolean}
          }
        })
      end
    end
  end
end
