# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Which side of the law hands the recipe out: "lawful" and "outlaw" come
        # from the org's `entityLawful` flag, "neutral" from the short list of
        # orgs that work both sides. Null for a source the export leaves
        # unattributed.
        #
        # Nullable enums get a component of their own rather than
        # anyOf: [$ref, {type: :null}] — see NullableInventoryItemTypeEnum.
        class NullableBlueprintSourceAlignmentEnum
          include OpenapiRuby::Components::Base

          VALUES = (::BlueprintSource::ALIGNMENTS + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": ::BlueprintSource::ALIGNMENTS.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
