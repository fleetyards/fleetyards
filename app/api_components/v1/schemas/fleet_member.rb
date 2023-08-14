# frozen_string_literal: true

module V1
  module Schemas
    class FleetMember
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid}
        }
      })
    end
  end
end
