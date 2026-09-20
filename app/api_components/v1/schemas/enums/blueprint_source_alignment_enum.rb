# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Which side of the law hands a recipe out, as a filter can ask for it:
      # the three values a source can carry and nothing else.
      #
      # The nullable twin `Shared::V1::Schemas::Enums::NullableBlueprintSourceAlignmentEnum`
      # is what a source *states*, null included, because nine of them are left
      # unattributed. Asking for those is not a question -- `withKnownSource`
      # already covers "nothing hands this out" -- so the filter takes this one.
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
