# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarSyncStatusEnum
        include OpenapiRuby::Components::Base

        # Read off the model so a state added to `Import` cannot drift from
        # what the sync reports.
        VALUES = ::Import.aasm.states.map { |state| state.name.to_s }.freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
