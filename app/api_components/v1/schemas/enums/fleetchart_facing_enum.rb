# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetchartFacingEnum
        include OpenapiRuby::Components::Base

        schema({
          type: [:string, :null],
          enum: ::FleetchartLayout::FACINGS + [nil],
          "x-enumNames": ::FleetchartLayout::FACINGS.map { |v| transform_enum_key(v) } + ["NULL"]
        })
      end
    end
  end
end
