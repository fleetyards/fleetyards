# frozen_string_literal: true

module V1
  module Schemas
    class UserFeature
      include Rswag::SchemaComponents::Component

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          enabled: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[name enabled]
      })
    end
  end
end
