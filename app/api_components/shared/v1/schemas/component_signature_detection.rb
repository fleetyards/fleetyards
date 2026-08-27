# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentSignatureDetection
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            ir: ComponentSignatureSensitivity,
            em: ComponentSignatureSensitivity,
            cs: ComponentSignatureSensitivity,
            rs: ComponentSignatureSensitivity
          },
          additionalProperties: false
        })
      end
    end
  end
end
