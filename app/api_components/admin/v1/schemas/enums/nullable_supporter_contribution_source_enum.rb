# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        # See NullableInventoryItemTypeEnum for why nullable enums are their own
        # component instead of anyOf: [$ref, {type: :null}].
        #
        # Null is "nobody stated a platform", which `other` deliberately does not
        # mean -- so the absence has to be expressible in the payload, the filter
        # and the form rather than being coerced into a value.
        class NullableSupporterContributionSourceEnum
          include OpenapiRuby::Components::Base

          VALUES = (SupporterContributionSourceEnum::SOURCES + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": SupporterContributionSourceEnum::SOURCES.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
