# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class InventoryTransferStateEnum
        include OpenapiRuby::Components::Base

        # Four terminal states rather than one `closed` with a reason: who is
        # told, and what they are told, differs per outcome, and the inbox
        # filters on it.
        VALUES = %w[pending completed declined cancelled expired].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
