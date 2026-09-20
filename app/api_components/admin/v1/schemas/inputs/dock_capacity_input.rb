# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class DockCapacityInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              dockId: {type: :string, format: :uuid},
              ladder: {type: :string},
              size: {type: :string},
              quantity: {type: :integer},
              display: {type: :boolean}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
