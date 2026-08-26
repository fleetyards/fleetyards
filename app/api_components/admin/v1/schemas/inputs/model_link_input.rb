# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelLinkInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              modelId: {type: :string, format: :uuid}
            },
            required: [:modelId]
          })
        end
      end
    end
  end
end
