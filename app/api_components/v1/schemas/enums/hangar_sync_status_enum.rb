# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarSyncStatusEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[created started finished failed].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
