# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class RsiHangarItemKindEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::HangarSync::ITEM_TYPES
        })
      end
    end
  end
end
