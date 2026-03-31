# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetInviteUrlCreateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            limit: {type: :integer, nullable: true},
            expiresAfterMinutes: {type: :integer, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
