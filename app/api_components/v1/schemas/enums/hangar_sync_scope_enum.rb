# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarSyncScopeEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Import::SYNC_SCOPES

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) },
          description: "full reads the whole pledge list; ccus reads only the upgrades and syncs only the CCUs"
        })
      end
    end
  end
end
