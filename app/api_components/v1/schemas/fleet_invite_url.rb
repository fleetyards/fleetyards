# frozen_string_literal: true

module V1
  module Schemas
    class FleetInviteUrl < FleetInviteUrlMinimal
      include SchemaConcern

      schema({
        properties: {}
      })
    end
  end
end
