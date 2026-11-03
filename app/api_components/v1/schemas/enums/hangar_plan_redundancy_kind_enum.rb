# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanRedundancyKindEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlans::Suggestions::REDUNDANCY_KINDS,
          "x-enumNames": ::HangarPlans::Suggestions::REDUNDANCY_KINDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
