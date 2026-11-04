# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetchartBackgroundEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::FleetchartLayout::BACKGROUNDS,
          "x-enumNames": ::FleetchartLayout::BACKGROUNDS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
