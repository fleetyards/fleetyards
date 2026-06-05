# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelModulePackageInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              description: {type: [:string, :null]},
              modelId: {type: :string, format: :uuid},
              pledgePrice: {type: [:number, :null]},
              active: {type: :boolean},
              hidden: {type: :boolean},
              storeImage: {type: :string},
              angledView: {type: :string},
              sideView: {type: :string},
              topView: {type: :string},
              moduleIds: {type: :array, items: {type: :string, format: :uuid}}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
