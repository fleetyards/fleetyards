# frozen_string_literal: true

module V1
  module Schemas
    class PieChartStats
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          y: {type: :integer},
          selected: {type: :boolean},
          sliced: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[name y selected sliced]
      })
    end
  end
end
