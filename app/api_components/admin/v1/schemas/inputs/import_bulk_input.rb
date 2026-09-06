# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ImportBulkInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              # The rows ticked in the table. Which of them the action has
              # anything to do to is decided server side.
              ids: {type: :array, items: {type: :string, format: :uuid}}
            },
            additionalProperties: false,
            required: %w[ids]
          })
        end
      end
    end
  end
end
