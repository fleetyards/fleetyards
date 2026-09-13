# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetAllianceCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[slug]
        })
      end
    end
  end
end
