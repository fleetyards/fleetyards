# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ModelModuleUpdateBulkInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              ids: {type: :array, items: {type: :string, format: :uuid}},
              active: {type: :boolean},
              hidden: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[ids]
          })
        end
      end
    end
  end
end
