# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetRoleUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string}
          },
          required: %w[name],
          additionalProperties: false
        })
      end
    end
  end
end
