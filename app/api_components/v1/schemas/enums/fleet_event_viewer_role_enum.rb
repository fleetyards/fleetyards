# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetEventViewerRoleEnum
        include OpenapiRuby::Components::Base

        # The caller's own standing on the event, not a persisted column.

        VALUES = %w[creator admin moderator].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
