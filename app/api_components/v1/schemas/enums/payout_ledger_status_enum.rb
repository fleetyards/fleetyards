# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class PayoutLedgerStatusEnum
        include OpenapiRuby::Components::Base

        VALUES = ::PayoutLedger::STATUSES.freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
