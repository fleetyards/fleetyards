# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanPurchaseKindEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlans::Summary::PURCHASE_KINDS,
          "x-enumNames": ::HangarPlans::Summary::PURCHASE_KINDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
