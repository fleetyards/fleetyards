# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanSlotStateEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlanSlot::STATES,
          "x-enumNames": ::HangarPlanSlot::STATES.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
