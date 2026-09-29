# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # See NullableInventoryItemTypeEnum for why nullable enums are their own
        # component instead of anyOf: [$ref, {type: :null}].
        class NullableFleetFidClaimCancelReasonEnum
          include OpenapiRuby::Components::Base

          VALUES = (::FleetFidClaim.cancel_reasons.keys + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": ::FleetFidClaim.cancel_reasons.keys.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
