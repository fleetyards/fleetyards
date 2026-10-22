# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanSourceIssueKindEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlans::Drift::SOURCE_KINDS,
          "x-enumNames": ::HangarPlans::Drift::SOURCE_KINDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
