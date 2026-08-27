# frozen_string_literal: true

module V1
  module Schemas
    class ScDataVersion
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          version: {type: :string}
        },
        additionalProperties: false,
        required: %i[version]
      })
    end
  end
end
