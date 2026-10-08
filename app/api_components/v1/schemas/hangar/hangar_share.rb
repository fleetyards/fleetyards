# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarShare
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            enabled: {type: :boolean},
            shareUrl: {type: [:string, :null], format: :uri}
          },
          required: %w[enabled shareUrl],
          additionalProperties: false
        })
      end
    end
  end
end
