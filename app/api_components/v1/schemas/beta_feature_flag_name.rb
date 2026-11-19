# frozen_string_literal: true

module V1
  module Schemas
    # The flags in config/feature_flags.yml that are not permanent, so the
    # generated client can mark the features behind them as beta. Unreferenced
    # by any request or response for the same reason as FeatureFlagName.
    class BetaFeatureFlagName
      include OpenapiRuby::Components::Base

      NAMES = FeatureFlags::Registry.load.beta_names.sort.freeze

      schema({
        type: :string,
        enum: NAMES,
        "x-enumNames": NAMES.map { |name| transform_enum_key(name) }
      })
    end
  end
end
