# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Modules
          class AdminModelModuleHardpoint
            include OpenapiRuby::Components::Base

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                modelId: {type: :string, format: :uuid},
                slot: {type: :string}
              },
              additionalProperties: false
            })
          end
        end
      end
    end
  end
end
