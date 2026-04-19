# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Modules
          class ModelModule < ::V1::Schemas::Models::Modules::ModelModule
            include Rswag::SchemaComponents::Component

            schema({
              properties: {
                price: {type: :number},
                active: {type: :boolean},
                hidden: {type: :boolean},
                model: {"$ref": "#/components/schemas/Model"},
                models: {type: :array, items: {"$ref": "#/components/schemas/Model"}}
              }
            })
          end
        end
      end
    end
  end
end
