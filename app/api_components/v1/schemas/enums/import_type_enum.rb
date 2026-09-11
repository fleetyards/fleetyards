# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Only the two types a user can own. The public imports resource is scoped
      # by `user_id`, which reaches exactly these; the admin schema carries the
      # full list.
      class ImportTypeEnum
        include OpenapiRuby::Components::Base

        TYPES = %w[Imports::HangarImport Imports::HangarSync].freeze

        schema({
          type: :string,
          enum: TYPES,
          "x-enumNames": TYPES.map { |type| transform_enum_key(type) }
        })
      end
    end
  end
end
