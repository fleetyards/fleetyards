# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetDiscordConnectionCodeEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[ok missing_token missing_guild invalid_token bot_not_in_guild guild_not_found discord_error].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-extensible-enum": VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
