# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanCartItemKindEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlans::Summary::CART_ITEM_KINDS,
          "x-enumNames": ::HangarPlans::Summary::CART_ITEM_KINDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
