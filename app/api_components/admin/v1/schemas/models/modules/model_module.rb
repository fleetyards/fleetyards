# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Modules
          class ModelModule < ::V1::Schemas::Models::Modules::ModelModule
            include OpenapiRuby::Components::Base

            schema({
              properties: {
                price: {type: :number},
                active: {type: :boolean},
                hidden: {type: :boolean},
                models: {type: :array, items: {"$ref": "#/components/schemas/Model"}},
                moduleHardpoints: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: {type: :string, format: :uuid},
                      modelId: {type: :string, format: :uuid},
                      slot: {type: :string}
                    },
                    additionalProperties: false
                  }
                }
              }
            })
          end
        end
      end
    end
  end
end
