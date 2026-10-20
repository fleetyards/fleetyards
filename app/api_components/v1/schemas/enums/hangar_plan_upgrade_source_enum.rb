# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanUpgradeSourceEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlanUpgradeStep::SOURCE_KINDS,
          "x-enumNames": ::HangarPlanUpgradeStep::SOURCE_KINDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
