# frozen_string_literal: true

module V1
  module Schemas
    class FleetMember < FleetMemberMinimal
      include SchemaConcern

      schema({
        properties: {}
      })
    end
  end
end
