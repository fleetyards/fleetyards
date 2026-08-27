# frozen_string_literal: true

module V1
  module Schemas
    class UserFeatureFleet
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string}
        },
        additionalProperties: false,
        required: %w[name slug]
      })
    end
  end
end
