# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Single value on purpose: POST /hangar/sync only ever answers "queued".
      # HangarSyncStatusEnum carries the states the sync itself moves through.
      class HangarSyncSubmitStatusEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[pending].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
