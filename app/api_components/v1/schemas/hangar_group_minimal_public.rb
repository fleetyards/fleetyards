# frozen_string_literal: true

module V1
  module Schemas
    class HangarGroupMinimalPublic < HangarGroupPublic
      include SchemaConcern

      schema({
        properties: {
          sort: {type: :integer, nullable: true},
          vehiclesCount: {type: :integer}
        },
        required: %w[vehiclesCount]
      })
    end
  end
end
