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
              modelId: {type: :string, format: :uuid},
              slot: {type: [:string, :null], description: "The module hardpoint's name on the hull; blank clears it"}
            },
            required: [:modelId]
          })
        end
      end
    end
  end
end
