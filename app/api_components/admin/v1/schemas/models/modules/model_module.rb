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
                cargo: {type: :number},
                active: {type: :boolean},
                hidden: {type: :boolean},
                componentId: {
                  type: [:string, :null],
                  format: :uuid,
                  description: "The part the module is in the game files, by sc_key. Present on a single module."
                },
                models: {type: :array, items: {"$ref": "#/components/schemas/Model"}},
                moduleHardpoints: {
                  type: :array,
                  items: AdminModelModuleHardpoint
                }
              }
            })
          end
        end
      end
    end
  end
end
