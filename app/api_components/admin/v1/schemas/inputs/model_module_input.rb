# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelModuleInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              description: {type: :string, nullable: true},
              modelId: {type: :string, format: :uuid, nullable: true},
              manufacturerId: {type: :string, format: :uuid},
              price: {type: :number, nullable: true},
              pledgePrice: {type: :number, nullable: true},
              productionStatus: {type: :string},
              active: {type: :boolean},
              hidden: {type: :boolean},
              storeImage: {type: :string},
              scKey: {type: :string, nullable: true}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
