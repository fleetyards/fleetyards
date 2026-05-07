# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelUpgradeInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              description: {type: :string, nullable: true},
              modelId: {type: :string, format: :uuid, nullable: true},
              pledgePrice: {type: :number, nullable: true},
              active: {type: :boolean},
              hidden: {type: :boolean},
              storeImage: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
