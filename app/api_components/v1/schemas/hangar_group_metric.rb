# frozen_string_literal: true

module V1
  module Schemas
    class HangarGroupMetric
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          slug: {type: :string},
          count: {type: :integer}
        },
        required: %w[id slug count]
      })
    end
  end
end
