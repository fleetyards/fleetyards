# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class InventoryTransferReportReasonEnum
        include OpenapiRuby::Components::Base

        VALUES = ::InventoryTransferReport::REASONS.keys.map(&:to_s).freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
