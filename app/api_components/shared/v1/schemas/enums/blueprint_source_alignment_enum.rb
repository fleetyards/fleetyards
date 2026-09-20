# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Which side of the law hands a recipe out, where the answer is known:
        # the three values a source can carry and nothing else.
        #
        # The nullable twin `NullableBlueprintSourceAlignmentEnum` is what a
        # single source *states*, null included, because nine of them are left
        # unattributed. This one is what a blueprint's set of sides and the
        # filter over it are made of, neither of which can hold a blank.
        #
        # Shared rather than v1: `Admin::V1::Schemas::Blueprint` subclasses the
        # shared blueprint component and so inherits its reference to this.
        class BlueprintSourceAlignmentEnum
          include OpenapiRuby::Components::Base

          VALUES = ::BlueprintSource::ALIGNMENTS

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
