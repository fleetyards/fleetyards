# frozen_string_literal: true

module V1
  module Schemas
    class FactionDetail < ::V1::Schemas::Faction
      schema({
        properties: {
          description: {type: [:string, :null]},
          headquarters: {type: [:string, :null]},
          founded: {type: [:string, :null]},
          leadership: {type: [:string, :null]},
          ladders: {type: :array, items: ::V1::Schemas::FactionLadder}
        },
        required: %w[ladders]
      })
    end
  end
end
