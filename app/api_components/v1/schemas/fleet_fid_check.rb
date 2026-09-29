# frozen_string_literal: true

module V1
  module Schemas
    class FleetFidCheck
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          taken: {type: :boolean},
          # A free `X-N` to start with, when the taken FID could be an RSI SID:
          # its org can claim it once its own fleet is verified.
          suggestion: {type: :string}
        },
        additionalProperties: false,
        required: %i[taken]
      })
    end
  end
end
