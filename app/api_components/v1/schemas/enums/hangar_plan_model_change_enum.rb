# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanModelChangeEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlans::Comparison::CHANGES,
          "x-enumNames": ::HangarPlans::Comparison::CHANGES.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
