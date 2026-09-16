# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        # The two states an author picks. `publishing`, `published` and
        # `failed` are written by the publish job, so the input cannot name
        # them.
        class AnnouncementInputStatusEnum
          include OpenapiRuby::Components::Base

          AUTHORABLE = %w[draft scheduled].freeze

          schema({
            type: :string,
            enum: AUTHORABLE,
            "x-enumNames": AUTHORABLE.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
