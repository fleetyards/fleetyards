# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetCheckInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            fid: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
