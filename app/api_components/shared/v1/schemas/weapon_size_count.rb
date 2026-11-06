# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class WeaponSizeCount
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            size: {type: :integer},
            count: {type: :integer}
          },
          additionalProperties: false,
          required: %w[size count]
        })
      end
    end
  end
end
