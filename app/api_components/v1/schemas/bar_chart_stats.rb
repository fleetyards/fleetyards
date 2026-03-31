# frozen_string_literal: true

module V1
  module Schemas
    class BarChartStats
      include Rswag::SchemaComponents::Component

      schema({
        type: :object,
        properties: {
          label: {type: :string},
          count: {type: :integer},
          tooltip: {type: :string}
        },
        additionalProperties: false,
        required: %w[label count tooltip]
      })
    end
  end
end
