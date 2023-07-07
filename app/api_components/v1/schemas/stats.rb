# frozen_string_literal: true

module V1
  module Schemas
    class Stats
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          shipsCountYear: {type: :integer},
          shipsCountTotal: {type: :integer}
        },
        required: %w[shipsCountYear shipsCountTotal]
      })
    end
  end
end
