# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanIssueKindEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlans::Summary::ISSUE_KINDS,
          "x-enumNames": ::HangarPlans::Summary::ISSUE_KINDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
