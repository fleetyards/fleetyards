# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class SupporterTierProjection
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            tier: {type: :integer},
            expiresAt: {type: :string, format: :date}
          },
          additionalProperties: false,
          required: %w[tier expiresAt]
        })
      end
    end
  end
end
