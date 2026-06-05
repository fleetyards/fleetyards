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
              description: {type: [:string, :null]},
              modelId: {type: [:string, :null], format: :uuid},
              pledgePrice: {type: [:number, :null]},
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
