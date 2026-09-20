# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class DockAdditionInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              dockId: {type: :string, format: :uuid},
              modelId: {type: :string, format: :uuid}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
