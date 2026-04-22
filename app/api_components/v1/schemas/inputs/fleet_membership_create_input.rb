# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetMembershipCreateInput
        include OpenapiRuby::Components::Base

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
