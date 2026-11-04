# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetchartViewpointEnum
        include OpenapiRuby::Components::Base

        schema({
          type: [:string, :null],
          enum: ::FleetchartLayout::VIEWPOINTS + [nil],
          "x-enumNames": ::FleetchartLayout::VIEWPOINTS.map { |v| transform_enum_key(v) } + ["NULL"]
        })
      end
    end
  end
end
