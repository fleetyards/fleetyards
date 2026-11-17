# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Null for a size RSI's map has that the import does not know yet.
      class NullableJumpTunnelSizeEnum
        include OpenapiRuby::Components::Base

        schema({
          type: [:string, :null],
          enum: ::JumpTunnel::SIZES + [nil],
          "x-enumNames": ::JumpTunnel::SIZES.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
