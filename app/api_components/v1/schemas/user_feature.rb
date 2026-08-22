# frozen_string_literal: true

module V1
  module Schemas
    class UserFeature
      include OpenapiRuby::Components::Base

      # The enum is safe to declare here in a way FeatureFlagName is not: the
      # scopes are a closed set, so it will not grow a value on every new flag
      # and trip the breaking-change check.
      schema({
        type: :object,
        properties: {
          name: {type: :string},
          enabled: {type: :boolean},
          enabledForSelf: {type: :boolean},
          scope: {type: :string, enum: FeatureFlags::Definition::SELF_SERVICE_SCOPES},
          toggleable: {type: :boolean},
          fleets: {
            type: :array,
            items: {
              type: :object,
              properties: {
                name: {type: :string},
                slug: {type: :string}
              },
              additionalProperties: false,
              required: %w[name slug]
            }
          },
          groups: {
            type: :array,
            items: {type: :string}
          }
        },
        additionalProperties: false,
        required: %w[name enabled enabledForSelf scope toggleable fleets groups]
      })
    end
  end
end
