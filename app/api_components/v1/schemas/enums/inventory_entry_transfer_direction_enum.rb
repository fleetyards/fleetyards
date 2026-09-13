# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Which way the goods moved, seen from the ledger entry: a deposit
      # arrived, the withdrawal that paid for it left.
      class InventoryEntryTransferDirectionEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[in out].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
