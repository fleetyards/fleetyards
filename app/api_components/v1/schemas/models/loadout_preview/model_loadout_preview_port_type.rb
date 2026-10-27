# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module LoadoutPreview
        class ModelLoadoutPreviewPortType
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              type: {type: :string},
              subTypes: {type: :string}
            },
            additionalProperties: false,
            required: %w[type subTypes]
          })
        end
      end
    end
  end
end
