# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
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
