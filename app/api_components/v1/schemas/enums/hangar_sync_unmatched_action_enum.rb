# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarSyncUnmatchedActionEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Import::UNMATCHED_VEHICLES_ACTIONS

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
