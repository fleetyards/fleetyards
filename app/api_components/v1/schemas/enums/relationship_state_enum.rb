# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # The state of a friendship or a fleet alliance, *as the reading party
      # sees it*. `ignored` is only ever served to the side that ignored it --
      # to the side that asked, an ignored request reads as `pending`, which is
      # the whole point of having the state at all.
      class RelationshipStateEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[pending accepted declined ignored].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
