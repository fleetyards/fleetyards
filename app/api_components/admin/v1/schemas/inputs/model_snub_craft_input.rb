# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelSnubCraftInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              modelId: {type: :string, format: :uuid},
              snubCraftId: {type: :string, format: :uuid}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
