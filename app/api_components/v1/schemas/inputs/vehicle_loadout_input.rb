# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleLoadoutInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: [:string, :null]},
            kind: ::V1::Schemas::Enums::VehicleLoadoutKindEnum,
            url: {type: [:string, :null]},
            public: {type: :boolean},
            items: {type: :array, items: ::V1::Schemas::Inputs::VehicleLoadoutItemInput}
          },
          additionalProperties: false
        })
      end
    end
  end
end
