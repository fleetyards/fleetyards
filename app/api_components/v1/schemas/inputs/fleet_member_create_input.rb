# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetMemberCreateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            username: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
