# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class VehicleInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              name: {type: :string, nullable: true},
              serial: {type: :string, nullable: true},
              wanted: {type: :boolean},
              flagship: {type: :boolean},
              public: {type: :boolean},
              nameVisible: {type: :boolean},
              saleNotify: {type: :boolean},
              hidden: {type: :boolean},
              loaner: {type: :boolean},
              boughtVia: {type: :string, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
