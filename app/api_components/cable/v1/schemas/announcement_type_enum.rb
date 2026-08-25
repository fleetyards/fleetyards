# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # Named rather than inlined so the generated client gets a stable type
      # name: Modelina names an anonymous inline schema by position, which moves
      # whenever the document grows.
      class AnnouncementTypeEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[success info warning alert].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
