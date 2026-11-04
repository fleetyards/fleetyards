# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetchartShipStateEnum
        include OpenapiRuby::Components::Base

        schema({
          type: [:string, :null],
          enum: ::FleetchartLayout::STATES + [nil],
          "x-enumNames": ::FleetchartLayout::STATES.map { |v| transform_enum_key(v) } + ["NULL"]
        })
      end
    end
  end
end
