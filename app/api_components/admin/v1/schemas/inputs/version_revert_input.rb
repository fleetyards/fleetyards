# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class VersionRevertInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              field: {type: :string}
            },
            required: %w[field]
          })
        end
      end
    end
  end
end
