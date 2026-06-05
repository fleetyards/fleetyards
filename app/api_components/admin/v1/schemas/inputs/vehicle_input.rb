# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class VehicleInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: [:string, :null]},
              serial: {type: [:string, :null]},
              wanted: {type: :boolean},
              flagship: {type: :boolean},
              public: {type: :boolean},
              nameVisible: {type: :boolean},
              saleNotify: {type: :boolean},
              hidden: {type: :boolean},
              loaner: {type: :boolean},
              boughtVia: {type: [:string, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
