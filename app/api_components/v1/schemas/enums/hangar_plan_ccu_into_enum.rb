# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanCcuIntoEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::Model::CCU_TARGET_STATUSES,
          "x-enumNames": ::Model::CCU_TARGET_STATUSES.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
