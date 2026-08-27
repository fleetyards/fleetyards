# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class DockCount
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            count: {type: :integer},
            # Neither of these carries its enum, for different reasons. size is
            # humanized in the jbuilder ("Small", not "small"), so
            # DockShipSizeEnum does not describe it. type does hold raw
            # DockTypeEnum values, but putting the enum on a public response
            # makes every added dock type a response-property-enum-value-added
            # warning, and the public gate runs --fail-on WARN. Same reason
            # FeatureFlagName is referenced by nothing.
            size: {type: :string},
            type: {type: :string},
            typeLabel: {type: :string}
          },
          additionalProperties: false,
          required: %w[size count type typeLabel]
        })
      end
    end
  end
end
