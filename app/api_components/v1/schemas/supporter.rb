# frozen_string_literal: true

module V1
  module Schemas
    class Supporter
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          displayName: {type: :string},
          username: {type: :string}
        },
        additionalProperties: false,
        required: %w[displayName]
      })
    end
  end
end
