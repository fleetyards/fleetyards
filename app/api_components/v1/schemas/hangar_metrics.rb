# frozen_string_literal: true

module V1
  module Schemas
    class HangarMetrics
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          totalMoney: {type: :number},
          totalCredits: {type: :number},
          totalMinCrew: {type: :integer},
          totalMaxCrew: {type: :integer},
          totalCargo: {type: :number}
        },
        additionalProperties: false,
        required: %w[totalMoney totalCredits totalMinCrew totalMaxCrew totalCargo]
      })
    end
  end
end
