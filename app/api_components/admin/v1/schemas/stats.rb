# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Stats
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            onlineCount: {type: :integer},
            shipsCountYear: {type: :integer},
            shipsCountTotal: {type: :integer},
            usersCountTotal: {type: :integer},
            fleetsCountTotal: {type: :integer}
          },
          additionalProperties: false,
          required: %w[onlineCount shipsCountYear shipsCountTotal usersCountTotal fleetsCountTotal]
        })
      end
    end
  end
end
