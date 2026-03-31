# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetMembershipCreateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            token: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
