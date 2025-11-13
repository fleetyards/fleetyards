# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetInviteUrlCreateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            limit: {type: :integer},
            expiresAfterMinutes: {type: :integer}
          },
          additionalProperties: false
        })
      end
    end
  end
end
