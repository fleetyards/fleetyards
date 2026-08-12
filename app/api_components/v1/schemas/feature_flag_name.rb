# frozen_string_literal: true

module V1
  module Schemas
    # Every flag declared in config/feature_flags.yml, so the generated client
    # gets a union type to check `isFeatureEnabled` calls against.
    #
    # Deliberately not referenced by any request or response. GET /features keeps
    # returning a plain string array: an enum on a response makes every added
    # flag a `response-property-enum-value-added` warning, which the public API
    # breaking-change check fails on.
    class FeatureFlagName
      include OpenapiRuby::Components::Base

      schema({
        type: :string,
        enum: FeatureFlags::Registry.load.names.sort
      })
    end
  end
end
