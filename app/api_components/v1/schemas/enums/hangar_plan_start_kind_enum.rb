# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanStartKindEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlanAcquisition::START_KINDS,
          "x-enumNames": ::HangarPlanAcquisition::START_KINDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
