# frozen_string_literal: true

module V1
  module Schemas
    class JumpTunnel
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          entryCode: {type: :string},
          exitCode: {type: :string},
          size: ::V1::Schemas::Enums::NullableJumpTunnelSizeEnum,
          bidirectional: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[entryCode exitCode size bidirectional]
      })
    end
  end
end
