# frozen_string_literal: true

module V1
  module Schemas
    class CommodityItemType
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          value: {type: :string}
        },
        additionalProperties: false,
        required: %w[name value]
      })
    end
  end
end
