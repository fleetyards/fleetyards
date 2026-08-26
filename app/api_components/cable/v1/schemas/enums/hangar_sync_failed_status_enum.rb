# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      module Enums
        # Single value: it discriminates this message variant from the others on
        # the channel.
        class HangarSyncFailedStatusEnum
          include OpenapiRuby::Components::Base

          VALUES = %w[failed].freeze

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
