# frozen_string_literal: true

module V1
  module Schemas
    # Plain strings on purpose. Referencing FeatureFlagName here would put its
    # enum on a response, and every added flag then trips
    # response-property-enum-value-added in the breaking-change check.
    class FeatureNamesList
      include OpenapiRuby::Components::Base

      schema({
        type: :array,
        items: {type: :string}
      })
    end
  end
end
