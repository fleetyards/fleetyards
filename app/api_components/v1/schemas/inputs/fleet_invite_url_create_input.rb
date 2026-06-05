# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetInviteUrlCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            limit: {type: [:integer, :null]},
            expiresAfterMinutes: {type: [:integer, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
