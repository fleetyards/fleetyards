# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # Either a username to look up, or a plain name for someone with no
      # account at all.
      class PayoutParticipantCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            username: {type: [:string, :null]},
            name: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
